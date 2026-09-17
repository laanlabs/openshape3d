"""Round 6, agent B — 18.19, 18.23, 18.8A, 18.8B, 15.8. Recipes follow
level18.py / level15.py conventions: a single printed volume is a float, a
configurations sheet passes [(label, volume), ...] and build() returns one
body-id list per configuration."""
import math
from kit import (Sketch, front, back, top, bottom, right, left, extrude, revolve, fillet, chamfer,
                 shell, edges_where, edges, faces, union, subtract, bodies, pattern, mirror, plane_at,
                 move, G, X)

PROBLEMS = {}


def problem(pid, volume, unit="mm", features=("Extrude Boss", "Extrude Cut")):
    def deco(fn):
        if isinstance(volume, (list, tuple)):
            meta = {"volume": volume[0][1], "configs": list(volume), "unit": unit, "features": list(features)}
        else:
            meta = {"volume": volume, "unit": unit, "features": list(features)}
        PROBLEMS[pid] = (meta, fn)
        return fn
    return deco


# ------------------------------------------------------------ helpers ---

def _arc_short(sk, c, r, p, q):
    """Arc of radius r about c between points p and q, the short way."""
    a0 = math.degrees(math.atan2(p[1] - c[1], p[0] - c[0]))
    a1 = math.degrees(math.atan2(q[1] - c[1], q[0] - c[0]))
    sweep = (a1 - a0) % 360
    if sweep > 180:
        a0, a1 = a1, a0
        sweep = 360 - sweep
    sk.arc(c, r, a0, a0 + sweep)


def _corner(p0, p1, p2, r):
    """Sketch-fillet of radius r at corner p1 (edges p0-p1, p1-p2):
    (tangent on p0-p1, tangent on p1-p2, centre)."""
    a = (p0[0] - p1[0], p0[1] - p1[1]); b = (p2[0] - p1[0], p2[1] - p1[1])
    la, lb = math.hypot(*a), math.hypot(*b)
    a = (a[0] / la, a[1] / la); b = (b[0] / lb, b[1] / lb)
    theta = math.acos(max(-1.0, min(1.0, a[0] * b[0] + a[1] * b[1])))
    d = r / math.tan(theta / 2)
    ta = (p1[0] + a[0] * d, p1[1] + a[1] * d)
    tb = (p1[0] + b[0] * d, p1[1] + b[1] * d)
    bis = (a[0] + b[0], a[1] + b[1]); lb2 = math.hypot(*bis)
    c = (p1[0] + bis[0] / lb2 * r / math.sin(theta / 2), p1[1] + bis[1] / lb2 * r / math.sin(theta / 2))
    return ta, tb, c


def _open_chain(sk, pts, radii):
    """Polyline pts[0]..pts[-1] with interior corners rounded (radii[i] for
    pts[i]; the two ends stay sharp). Returns nothing; the caller closes."""
    n = len(pts)
    cur = pts[0]
    for i in range(1, n - 1):
        r = radii[i]
        if r <= 0:
            sk.line(cur, pts[i]); cur = pts[i]
            continue
        ta, tb, c = _corner(pts[i - 1], pts[i], pts[i + 1], r)
        sk.line(cur, ta)
        _arc_short(sk, c, r, ta, tb)
        cur = tb
    sk.line(cur, pts[-1])


# ----------------------------------------------------------------- 18.19 ---

@problem("18.19", 3108.35, features=("Extrude Boss", "Extrude Cut", "Fillet", "Linear Pattern",
                                     "Hole Wizard (as cut)"))
def p18_19():
    # Lever, origin at the boss centre, front plane = the drawn profile,
    # arm 7 thick (z 0..7), O13 boss 9 long (z 0..9, 2 proud on the front),
    # O6 bore. Arm outline: vertical x = 6.5 tangent to the boss up to y = 5,
    # flat y = 5 to the 30 deg lower slope that lands at (30, 0), flat y = 0
    # to x = 47, end 5 tall, flat y = 5 back to the 36 deg upper slope that
    # rises to the apex (15, 17), a 30 deg slope down to the y = 12 flat
    # (kink at 15 - 5/tan30), the flat to x = -3 and a line tangent to the
    # boss. Blue R1 on the arm's lateral corners (top view bands at the
    # (-3,12), kink, apex, (31.5,5), (47,5) corners; right view (47,0);
    # Detail C's (6.5,5) corner), orange R0.5 round the arm outline on both
    # faces (not the boss). Detail A: O4 at (14, 8), O2 at (9, 8) and
    # (19, 8) through. Detail C / Section D-D: a window pocket 5 deep from
    # the front leaving a 2 wall, sides parallel to the left edge 2 and 9
    # in (7 apart), top y = 10, bottom the boss circle, R1 TYP corners.
    # Detail B: five 1 x 1 grooves at 2 pitch (last 3 from the end) in the
    # top and bottom faces of the tip, 5 long from the front face.
    t30, t36 = math.tan(math.radians(30)), math.tan(math.radians(36))
    th = math.asin(6.5 / math.hypot(3, 12)) - math.atan2(3, 12)      # left edge lean
    n = (math.cos(th), -math.sin(th)); d = (-math.sin(th), -math.cos(th))
    tt = -(-3 * d[0] + 12 * d[1])
    T = (-3 + tt * d[0], 12 + tt * d[1])                             # tangent point on the boss
    kx, bx, ux = 15 - 5 / t30, 30 - 5 / t30, 15 + 12 / t36
    pts = [(6.5, 0), (6.5, 5), (bx, 5), (30, 0), (47, 0), (47, 5), (ux, 5), (15, 17), (kx, 12), (-3, 12), T]
    radii = [0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0]
    sk = Sketch(front(0))
    _open_chain(sk, pts, radii)
    sk.arc((0, 0), 6.5, math.degrees(math.atan2(T[1], T[0])), 360)
    arm = extrude(sk, (40, 2.5), 7)
    rim = edges_where(arm, lambda e: abs(e["midpoint"][2]) < 0.05 or abs(e["midpoint"][2] - 7) < 0.05)
    fillet(arm, 0.5, rim)
    body = arm
    # window pocket (cut before the boss goes on: a pocket whose floor arc
    # lies on the finished boss cylinder and whose R1 corners are tangent
    # to it leaves the kernel an edge with a 12.9 mm tolerance)
    xl = (-4.5 - n[1] * 10) / n[0]; xr = (2.5 - n[1] * 10) / n[0]
    TL, TR = (xl, 10), (xr, 10)
    far = lambda P: (P[0] + d[0] * 3, P[1] + d[1] * 3)                # a point further down the side
    tl_a, tl_b, tl_c = _corner(far(TL), TL, TR, 1)                  # tl_a on the left side, tl_b on top
    tr_a, tr_b, tr_c = _corner(TL, TR, far(TR), 1)                  # tr_a on top, tr_b on the right side
    cL = (-3.5 * n[0] - math.sqrt(44) * d[0], -3.5 * n[1] - math.sqrt(44) * d[1])
    cR = (1.5 * n[0] - math.sqrt(54) * d[0], 1.5 * n[1] - math.sqrt(54) * d[1])
    bl_line = (cL[0] - n[0], cL[1] - n[1]); bl_circ = (cL[0] * 6.5 / 7.5, cL[1] * 6.5 / 7.5)
    br_line = (cR[0] + n[0], cR[1] + n[1]); br_circ = (cR[0] * 6.5 / 7.5, cR[1] * 6.5 / 7.5)
    win = Sketch(front(7))
    win.line(tl_b, tr_a)
    _arc_short(win, tr_c, 1, tr_a, tr_b)
    win.line(tr_b, br_line)
    _arc_short(win, cR, 1, br_line, br_circ)
    _arc_short(win, (0, 0), 6.5, br_circ, bl_circ)
    _arc_short(win, cL, 1, bl_circ, bl_line)
    win.line(bl_line, tl_a)
    _arc_short(win, tl_c, 1, tl_a, tl_b)
    extrude(win, (1.5, 8.5), -5, cut=[body])
    extrude(Sketch(front(0)).circle((0, 0), 6.5), (0, 0), 9, union=[arm])
    extrude(Sketch(front(10)).circle((0, 0), 3), (0, 0), -11, cut=[body])
    extrude(Sketch(front(10)).circle((14, 8), 2), (14, 8), -11, cut=[body])
    extrude(Sketch(front(10)).circle((9, 8), 1), (9, 8), -11, cut=[body])
    extrude(Sketch(front(10)).circle((19, 8), 1), (19, 8), -11, cut=[body])
    # Detail B grooves: one cutter each side, patterned x5 at 2
    before = {b["id"] for b in bodies()}
    top_g = extrude(Sketch(front(8)).rect(35, 4, 36, 6), (35.5, 5), -6, new_body=True)
    pattern(top_g, "linear", 5, axis=(1, 0, 0), spacing=2)
    bot_g = extrude(Sketch(front(8)).rect(35, -1, 36, 1), (35.5, 0), -6, new_body=True)
    pattern(bot_g, "linear", 5, axis=(1, 0, 0), spacing=2)
    tools = [b["id"] for b in bodies() if b["id"] not in before]
    assert len(tools) == 10, f"expected ten groove cutters, found {len(tools)}"
    subtract(body, tools)
    return body


# ----------------------------------------------------------------- 18.23 ---

def _hull3(sk, R1, r2, d):
    """Outline of a centre circle R1 at the origin and two end circles r2 at
    (+-d, 0): the tangent lines and the four arcs (flange 'diamond')."""
    al = math.acos((R1 - r2) / d)
    ca, sa = math.cos(al), math.sin(al)
    for sx in (1, -1):
        for sy in (1, -1):
            p1 = (sx * R1 * ca, sy * R1 * sa)
            p2 = (sx * (d + r2 * ca), sy * r2 * sa)
            sk.line(p1, p2)
    a = math.degrees(al)
    sk.arc((d, 0), r2, -a, a)
    sk.arc((-d, 0), r2, 180 - a, 180 + a)
    sk.arc((0, 0), R1, a, 180 - a)
    sk.arc((0, 0), R1, 180 + a, 360 - a)
    return sk


def _face_ids(bid, pred):
    return [f["index"] for f in faces(bid) if pred(f["centroid"], f["normal"])]


@problem("18.23", 43690.6, features=("Extrude Boss", "Revolve", "Fillet", "Shell", "Rib (as extrude)",
                                     "Extrude Cut"))
def p18_23():
    # Elbow fitting, origin at the flange top centre, y up, side pipe +z.
    # Flange: R28 centre, R13 ends at x = +-38 with O9 holes, 13 thick
    # (y -13..0). Revolved body: an R19 dome centred on the origin (38 REF at
    # the flange), O25 neck to the 35 step, O33 cup to 58. Side pipe O22 on
    # y = 24 (34 below the top) out to z = 50. R3 ALL FILLETS before the
    # shell: flange top outline, flange/dome, dome/neck, both edges of the
    # 4-wide step at 35 (two R3 fillets on a 4 ledge meet as an S curve,
    # Section B-B's sharp inner corner at 37.8), pipe/body junction. Shell 3
    # inward, open at the flange bottom, cup top and pipe end. Ribs 3 thick
    # in the flange cavity up to its ceiling: the O45 ring (O42..O48) and a
    # rib on the x axis from the ring to each bolt-hole ring. Section B-B
    # scanned: dome R19 about the origin, inner corner at 37.8, R6 inner
    # foot blend at r 20 = -2.7, ceiling -3, bore O16, ring r 21..24,
    # ribs 3. Builds 44024.8 (+0.77 %). The kernel cannot roll the pipe
    # junction's R3 over the S step (nor its R6 offset over the inner dome
    # torus), so both run against the plain neck cylinder; the bottom view's
    # see-through keyhole reaches z = 13 where this model's stops at 10.3,
    # i.e. SW's blend bridges pipe top to cup wall and removes more wall
    # (x = 0 sections: about -15 mm2 at the top, -21 mm2 at the bottom).
    body = extrude(_hull3(Sketch(top(-13)), 28, 13, 38), (0, 0), 13)
    s3 = math.sqrt
    cf = (15.5, s3(22 ** 2 - 15.5 ** 2))                  # dome/neck fillet centre
    tdome = (cf[0] * 19 / 22, cf[1] * 19 / 22)
    h1, h2 = 35 + s3(8), 35 - s3(8)                        # S-curve arc centres (convex, concave)
    prof = Sketch(front(0))
    prof.line((0, -3), (s3(19 ** 2 - 9), -3))
    prof.arc((0, 0), 19, math.degrees(math.asin(-3 / 19)), math.degrees(math.atan2(tdome[1], tdome[0])))
    _arc_short(prof, cf, 3, tdome, (12.5, cf[1]))
    prof.line((12.5, cf[1]), (12.5, 40)).line((12.5, 40), (0, 40)).line((0, 40), (0, -3))
    revolve(prof, (6, 20), (0, 0), (0, 1), union=[body])
    extrude(Sketch(front(0)).circle((0, 24), 11), (0, 24), 50, union=[body])
    # R3 fillets: flange top outline, dome foot, pipe junction
    outline = edges_where(body, lambda e: abs(e["midpoint"][1]) < 0.05 and math.hypot(e["midpoint"][0], e["midpoint"][2]) > 21
                          and min(math.hypot(e["midpoint"][0] - 38, e["midpoint"][2]), math.hypot(e["midpoint"][0] + 38, e["midpoint"][2])) > 6)
    assert len(outline) == 8, f"flange outline edges: {len(outline)}"
    fillet(body, 3, outline)
    foot = edges_where(body, lambda e: abs(e["midpoint"][1]) < 0.05 and abs(math.hypot(e["midpoint"][0], e["midpoint"][2]) - 19) < 0.1)
    assert foot, "no dome foot edge"
    fillet(body, 3, foot)
    pipe_face = _face_ids(body, lambda c, n: abs(c[1] - 24) < 0.5 and 20 < c[2] < 40)
    end_face = _face_ids(body, lambda c, n: n[2] > 0.99 and abs(c[2] - 50) < 0.05)
    assert len(pipe_face) == 1 and len(end_face) == 1, (pipe_face, end_face)
    junction = [e["index"] for e in G(f"/v1/edges?body={body}")["edges"]
                if pipe_face[0] in (e.get("faces") or []) and end_face[0] not in (e.get("faces") or [])]
    assert junction, "no pipe junction edges"
    fillet(body, 3, junction)
    # the cup and the S-curve step go on after the pipe fillet (OCCT cannot
    # roll an R3 ball through the 19.5 deg wedge between the pipe top and
    # the S curve's inflection)
    cup = Sketch(front(0))
    cup.line((0, h2), (12.5, h2))
    _arc_short(cup, (15.5, h2), 3, (12.5, h2), (14.5, 35))
    _arc_short(cup, (13.5, h1), 3, (14.5, 35), (16.5, h1))
    cup.line((16.5, h1), (16.5, 58)).line((16.5, 58), (0, 58)).line((0, 58), (0, h2))
    revolve(cup, (8, 45), (0, 0), (0, 1), union=[body])
    # Shell 3 as an explicit cavity (feature.shell refuses this body: "failed
    # validity checking", and "C0Geometry" once the pipe fillet is on). The
    # inward offset of a convex R3 fillet is a sharp corner, of a concave R3
    # fillet an R6 arc about the same centre.
    before = {b["id"] for b in bodies()}
    extrude(_hull3(Sketch(top(-14)), 25, 10, 38), (0, 0), 11)             # flange cavity, ceiling y = -3
    c0 = (s3(22 ** 2 - 9), 3.0)                                            # dome foot fillet centre
    t16 = (c0[0] * 16 / 22, c0[1] * 16 / 22)
    t16b = (cf[0] * 16 / 22, cf[1] * 16 / 22)

    def inner_profile(straight_neck):
        sk = Sketch(front(0))
        sk.line((0, -4), (c0[0], -4)).line((c0[0], -4), (c0[0], -3))
        _arc_short(sk, c0, 6, (c0[0], -3), t16)
        sk.arc((0, 0), 16, math.degrees(math.atan2(t16[1], t16[0])), math.degrees(math.atan2(t16b[1], t16b[0])))
        _arc_short(sk, cf, 6, t16b, (9.5, cf[1]))
        if straight_neck:
            sk.line((9.5, cf[1]), (9.5, 45)).line((9.5, 45), (0, 45)).line((0, 45), (0, -4))
        else:
            sk.line((9.5, cf[1]), (9.5, h2))
            _arc_short(sk, (15.5, h2), 6, (9.5, h2), (13.5, h1))
            sk.line((13.5, h1), (13.5, 59)).line((13.5, 59), (0, 59)).line((0, 59), (0, -4))
        X("feature.revolve", {"sketchID": sk.commit().id, "seedPoint": [5, 20], "axisPoint": [0, 0],
                              "axisDirection": [0, 1], "angleDegrees": 360})

    inner_profile(False)
    extrude(Sketch(front(0)).circle((0, 24), 8), (0, 24), 51)             # pipe bore
    tools = [b["id"] for b in bodies() if b["id"] not in before]
    assert len(tools) == 3, tools
    cav = tools[0]
    # the bore's R6 blend (the offset of the outer R3) rolls between the
    # bore and the neck bore carried straight through (the kernel refuses
    # R6 against the inner dome torus / S curve: "too large for the local
    # geometry"); the inner revolve contains that cylinder.
    k = {b["id"] for b in bodies()}
    extrude(Sketch(top(5)).circle((0, 0), 9.5), (0, 0), 40)
    nb = [b["id"] for b in bodies() if b["id"] not in k][0]
    union(nb, [tools[2]])
    bore = _face_ids(nb, lambda c, n: abs(c[1] - 24) < 0.5 and 20 < c[2] < 45)
    bend = _face_ids(nb, lambda c, n: n[2] > 0.99 and abs(c[2] - 51) < 0.05)
    assert len(bore) == 1 and len(bend) == 1, (bore, bend)
    bj = [e["index"] for e in G(f"/v1/edges?body={nb}")["edges"]
          if bore[0] in (e.get("faces") or []) and bend[0] not in (e.get("faces") or [])]
    fillet(nb, 6, bj)
    union(cav, [tools[1], nb])
    subtract(body, [cav])
    # Rib (thin, 3): bolt-hole rings, the O45 ring and the x-axis ribs up to the ceiling
    for sx in (1, -1):
        extrude(Sketch(top(-13)).circle((sx * 38, 0), 7.5), (sx * 38, 0), 10.5, union=[body])
    extrude(Sketch(top(-13)).circle((0, 0), 24).circle((0, 0), 21), (22.5, 0), 10.5, union=[body])
    for sx in (1, -1):
        extrude(Sketch(top(-13)).rect(sx * 22.5, -1.5, sx * 32, 1.5), (sx * 27, 0), 10.5, union=[body])
    for sx in (1, -1):
        extrude(Sketch(top(1)).circle((sx * 38, 0), 4.5), (sx * 38, 0), -15, cut=[body])
    return body


# ------------------------------------------------------------ 18.8A / B ---

def _tri_hull(sk, pcd_r, r):
    """Outline of three circles of radius r on a pitch circle pcd_r at 90,
    210 and 330 deg: three tangent lines and three arcs."""
    angs = (90, 210, 330)
    for i, a in enumerate(angs):
        c = (pcd_r * math.cos(math.radians(a)), pcd_r * math.sin(math.radians(a)))
        sk.arc(c, r, a - 60, a + 60)
        b = angs[(i + 1) % 3]
        cb = (pcd_r * math.cos(math.radians(b)), pcd_r * math.sin(math.radians(b)))
        n = math.radians(a + 60)
        sk.line((c[0] + r * math.cos(n), c[1] + r * math.sin(n)), (cb[0] + r * math.cos(n), cb[1] + r * math.sin(n)))
    return sk


def _tri_pocket(sk, pcd_r, inset_r, ring_r):
    """Centre pocket: inside the hull of radius-inset_r circles, outside the
    three ring_r circles -- a hull-side segment between each pair of rings
    and each ring's arc facing the centre."""
    angs = (90, 210, 330)
    cs = [(pcd_r * math.cos(math.radians(a)), pcd_r * math.sin(math.radians(a))) for a in angs]
    half = math.sqrt(ring_r ** 2 - inset_r ** 2)
    ends = {}
    for i, a in enumerate(angs):
        c, cb = cs[i], cs[(i + 1) % 3]
        n = (math.cos(math.radians(a + 60)), math.sin(math.radians(a + 60)))   # side's outward normal
        t = (-n[1], n[0])
        on = lambda q, sgn: (q[0] + inset_r * n[0] + sgn * half * t[0], q[1] + inset_r * n[1] + sgn * half * t[1])
        # the ring/side crossing of each ring that faces the other ring
        p_i = min((on(c, 1), on(c, -1)), key=lambda q: math.dist(q, cb))
        p_b = min((on(cb, 1), on(cb, -1)), key=lambda q: math.dist(q, c))
        sk.line(p_i, p_b)
        ends[(i, "next")] = p_i
        ends[((i + 1) % 3, "prev")] = p_b
    for i in range(3):
        p, q, c = ends[(i, "prev")], ends[(i, "next")], cs[i]
        a0 = math.degrees(math.atan2(p[1] - c[1], p[0] - c[0]))
        a1 = math.degrees(math.atan2(q[1] - c[1], q[0] - c[0]))
        inward = math.degrees(math.atan2(-c[1], -c[0]))
        for s0, e0 in ((a0, a1), (a1, a0)):                 # the CCW sweep through the inward direction
            sweep = (e0 - s0) % 360
            if (inward - s0) % 360 < sweep:
                sk.arc(c, ring_r, s0, s0 + sweep)
                break
    return sk


def _build_18_8(D, inset):
    body = extrude(Sketch(front(0)).circle((0, 0), D / 2), (0, 0), 10)
    extrude(_tri_hull(Sketch(front(10)), 24, 18), (0, 0), 25, union=[body])
    for a in (90, 210, 330):
        c = (24 * math.cos(math.radians(a)), 24 * math.sin(math.radians(a)))
        extrude(Sketch(front(36)).circle(c, 13), c, -37, cut=[body])
    extrude(_tri_pocket(Sketch(front(35)), 24, 18 - inset, 18), (0, 0), -25, cut=[body])
    # back recess 5 deep inside the rim wall, O36 rings standing: one region
    # cut. On O90 the rings cross the rim circle; until the crossing-outline
    # fix (STATUS 2026-09-16) that region made an invalid tool, and this was
    # a disc cut with the rings put back and the bores re-cut (same volume
    # and edges, 14 features instead of 8).
    sk = Sketch(front(-1)).circle((0, 0), D / 2 - 5)
    for a in (90, 210, 330):
        sk.circle((24 * math.cos(math.radians(a)), 24 * math.sin(math.radians(a))), 18)
    extrude(sk, (0, 0), 6, cut=[body])
    return body


@problem("18.8A", 92076.8, features=("Extrude Boss", "Extrude Cut", "Shell (as cut)", "Fillet"))
def p18_8A():
    # Origin at the flange back-face centre, part axis +z. O100 x 10 flange;
    # triangular body 25 tall = hull of the three O36 tubes on the O48 pitch
    # circle (90/210/330 deg), O26 bores through. Centre pocket 25 deep to
    # the flange face: inside the hull inset 5 (5 TYP, the hull of R13
    # circles) and outside the O36 rings (Section C-C). Shell 5 from the
    # back face: the back is recessed 5 inside O90 except the O36 rings round
    # the bores (Detail A's 3-wide groove at r 42..45, the back view, the
    # section's 5 recess behind the pocket). R1 ALL FILLETS.
    body = _build_18_8(100, 5)
    # every edge except the six tangent seams of the hull (no midpoint)
    fillet(body, 1, [e["index"] for e in edges(body)])
    return body


@problem("18.8B", 88069.3, features=("Extrude Boss", "Extrude Cut", "Shell (as cut)", "Fillet", "Editing"))
def p18_8B():
    # 18.8A edited: flange O90 (rim wall 5, so the back recess is inside O80
    # and the O36 rings run into the rim wall -- Fillet 2's crescent tips),
    # centre pocket inset 10 TYP from the triangle outline (hull of R8
    # circles, outside the O36 rings). Everything else as 18.8A, R1 ALL
    # FILLETS. The same recipe with (100, 5) is 18.8A.
    body = _build_18_8(90, 10)
    fillet(body, 1, [e["index"] for e in edges(body)])
    return body


# ------------------------------------------------------------------ 15.8 ---

@problem("15.8", [("LH.1", 5039), ("LH.2", 13312), ("LH.3", 34517), ("LH.4", 36124)],
         features=("Extrude Boss (thin feature)", "Extrude Cut", "Configurations (as recipe)"))
def p15_8():
    # U hanger (thin feature, thickness applied from the inside out): inner
    # O B semicircle about the origin, straight legs A up from the arc
    # centre line, THK D outward, C wide (symmetric about the front plane);
    # a O7 hole through each leg, 10 below its top, centred in the width.
    # Hand (closed form): C (pi/2 ((B/2 + D)^2 - (B/2)^2) + 2 A D)
    # - 2 pi 3.5^2 D = 5039.4 / 13312.2 / 34516.6 / 36123.2.
    out = []
    for k, (A, B, C, D) in enumerate(((80, 60, 20, 1), (100, 85, 20, 2), (120, 90, 30, 3), (125, 95, 30, 3))):
        ox = k * 250.0
        R = B / 2
        sk = Sketch(front(0))
        sk.arc((ox, 0), R + D, 180, 360).arc((ox, 0), R, 180, 360)
        sk.poly([(ox + R + D, 0), (ox + R + D, A), (ox + R, A), (ox + R, 0)], close=False)
        sk.poly([(ox - R, 0), (ox - R, A), (ox - R - D, A), (ox - R - D, 0)], close=False)
        body = extrude(sk, (ox, -R - D / 2), C / 2, symmetric=True)     # symmetric: distance each side
        for sx in (1, -1):
            x0 = ox + sx * (R + D + 1)
            extrude(Sketch(right(x0)).circle((0, A - 10), 3.5), (0, A - 10), -sx * (D + 2), cut=[body])
        out.append([body])
    return out
