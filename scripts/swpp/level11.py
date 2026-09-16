"""Level 11 — Hole Wizard (12 problems). The app has no hole wizard; the
standard counterbore/countersink sizes are cut as stacked cylinders and
patterned with Transform › Pattern."""
import math
from kit import (Sketch, front, top, right, extrude, fillet, chamfer, edges_where,
                 pattern, subtract, union, bodies, vol)

PROBLEMS = {}


def problem(pid, volume, unit="mm", features=("Hole Wizard",)):
    def deco(fn):
        PROBLEMS[pid] = ({"volume": volume, "unit": unit, "features": list(features)}, fn)
        return fn
    return deco


# ANSI B18.3 socket-head cap screw counterbores (normal fit through holes)
CBORE = {"#8": (0.1770, 0.3130, 0.1640), "#10": (0.2010, 0.3750, 0.1900)}


@problem("11.1", 12.7, unit="in")
def p11_1():
    # IPS plate 0.50 thick: a 4.00 × 3.00 tab (x 0..4) joined to a 3.50 ×
    # 4.00 body (x 4..7.5) with R0.25 inside corners and 0.2 × 45° chamfers
    # on the four outer corners; 9 CBORE #8 holes on a 1.00 grid from
    # (4.75, 0) and 2 CBORE #10 holes 1.625 apart 2.00 from the left edge.
    s = 25.4
    plate = extrude(Sketch(top(0)).poly([(0, -1.5 * s), (4 * s, -1.5 * s), (4 * s, -2 * s), (7.5 * s, -2 * s),
                                          (7.5 * s, 2 * s), (4 * s, 2 * s), (4 * s, 1.5 * s), (0, 1.5 * s)]),
                    (2 * s, 0), 0.5 * s)
    # inside-corner rounds (the two vertical edges at x = 4, |v| = 1.5)
    fillet(plate, 0.25 * s, edges_where(plate, lambda e: abs(e["midpoint"][0] - 4 * s) < 0.5
                                        and abs(abs(e["midpoint"][2]) - 1.5 * s) < 0.5 and abs(e["lengthMM"] - 0.5 * s) < 0.5))
    chamfer(plate, 0.2 * s, edges_where(plate, lambda e: abs(e["lengthMM"] - 0.5 * s) < 0.5
                                        and ((abs(e["midpoint"][0]) < 0.5 and abs(abs(e["midpoint"][2]) - 1.5 * s) < 0.5)
                                             or (abs(e["midpoint"][0] - 7.5 * s) < 0.5 and abs(abs(e["midpoint"][2]) - 2 * s) < 0.5))))

    def cbore_cutter(x, v, spec):
        thru, cb, depth = CBORE[spec]
        c = extrude(Sketch(top(-0.1 * s)).circle((x, v), thru / 2 * s), (x, v), 0.7 * s, new_body=True)
        head = extrude(Sketch(top(0.5 * s - depth * s)).circle((x, v), cb / 2 * s), (x, v), depth * s + 0.1 * s, new_body=True)
        union(c, [head])
        return c

    # Sketch v = -z on the top plane: a hole drawn at v = -1.0 sits at world
    # z = +1.0, so the grid's second direction runs along -z.
    known = {b["id"] for b in bodies()}
    c8 = cbore_cutter(4.75 * s, -1.0 * s, "#8")
    pattern(c8, "linear", 3, axis=(1, 0, 0), spacing=1.0 * s)
    row = [b["id"] for b in bodies() if b["id"] not in known]
    for cid in list(row):
        pattern(cid, "linear", 3, axis=(0, 0, -1), spacing=1.0 * s)
    c10 = cbore_cutter(2.0 * s, -0.8125 * s, "#10")
    pattern(c10, "linear", 2, axis=(0, 0, -1), spacing=1.625 * s)
    tools = [b["id"] for b in bodies() if b["id"] not in known]
    assert len(tools) == 11, f"expected 11 hole cutters, found {len(tools)}"
    subtract(plate, tools)
    return plate


@problem("11.2", 29430, features=("Extrude Boss", "Hole (stacked cylinders)", "Pattern (as recipe)"))
def p11_2():
    # Plate 60 × 60 × 10; nine Ø8 through holes on a 3 × 3 grid rotated 45°
    # with 15 spacing about the centre; four M5 SHCS counterbores at the
    # corners (7 in): Ø5.5 through, Ø10 × 5 counterbore — the only size
    # pair that lands the 29430 (Ø9.5 × 5.4 is 0.3 % light).
    body = extrude(Sketch(top(0)).rect(0, 0, 60, 60), (30, 30), 10)
    s = 15 / math.sqrt(2)
    sk = Sketch(top(10))
    for i in (-1, 0, 1):
        for j in (-1, 0, 1):
            sk.circle((30 + (i + j) * s, 30 + (i - j) * s), 4)
    for i in (-1, 0, 1):
        for j in (-1, 0, 1):
            c = (30 + (i + j) * s, 30 + (i - j) * s)
            extrude(Sketch(top(10)).circle(c, 4), c, -10, cut=[body])
    for c in ((7, 7), (53, 7), (7, 53), (53, 53)):
        extrude(Sketch(top(10)).circle(c, 2.75), c, -10, cut=[body])
        extrude(Sketch(top(10)).circle(c, 5), c, -5, cut=[body])
    return body


@problem("11.3", 4.98, unit="in", features=("Extrude Boss", "Extrude Cut", "Hole (stacked cylinders)", "Pattern (as recipe)"))
def p11_3():
    # Disc Ø3.75 × 0.5625 with a Ø1.0 through hole ringed by a Ø1.25 × 0.125
    # recess (read as a recess: as a boss the part is 2.3 % heavy, and the
    # difference is exactly twice the ring); five 3/8 SHCS counterbores
    # (Ø0.4063 through, Ø0.5625 × 0.375) on R1.3125 from 270°, five 5/16-18
    # tapped holes (tap drill Ø0.257 through) between them.
    IN = 25.4
    disc = extrude(Sketch(top(0)).circle((0, 0), 1.875 * IN).circle((0, 0), 0.5 * IN), (1.2 * IN, 0), 0.5625 * IN)
    extrude(Sketch(top(0)).circle((0, 0), 0.625 * IN), (0, 0), 0.125 * IN, cut=[disc])
    for k in range(5):
        a = math.radians(270 + 72 * k)
        c = (1.3125 * IN * math.cos(a), 1.3125 * IN * math.sin(a))
        extrude(Sketch(top(0.5625 * IN)).circle(c, 0.4063 / 2 * IN), c, -0.5625 * IN, cut=[disc])
        extrude(Sketch(top(0.5625 * IN)).circle(c, 0.5625 / 2 * IN), c, -0.375 * IN, cut=[disc])
        b = math.radians(270 + 36 + 72 * k)
        t = (1.3125 * IN * math.cos(b), 1.3125 * IN * math.sin(b))
        extrude(Sketch(top(0.5625 * IN)).circle(t, 0.257 / 2 * IN), t, -0.5625 * IN, cut=[disc])
    return disc


# ------------------------------------------------------------ helpers ----

def _perp(n):
    """Two unit vectors e1, e2 with e1 x e2 = n (n a unit axis vector)."""
    import math as _m
    ax = (1, 0, 0) if abs(n[0]) < 0.9 else (0, 1, 0)
    e1 = (ax[1] * n[2] - ax[2] * n[1], ax[2] * n[0] - ax[0] * n[2], ax[0] * n[1] - ax[1] * n[0])
    l = _m.sqrt(sum(c * c for c in e1)); e1 = tuple(c / l for c in e1)
    e2 = (n[1] * e1[2] - n[2] * e1[1], n[2] * e1[0] - n[0] * e1[2], n[0] * e1[1] - n[1] * e1[0])
    return e1, e2


def csk_hole(body, center, n, depth, r_thru, r_csk, angle=90.0):
    """Hole Wizard countersunk hole: through hole of radius r_thru `depth`
    deep from `center` (a point ON the face) along the unit vector `n`
    (into the body), with a countersink of radius r_csk at the face. The
    cone is a revolve cut of a triangle in a plane through the axis."""
    from kit import plane_at, revolve
    e1, e2 = _perp(n)
    o = [center[i] - 0.1 * n[i] for i in range(3)]
    extrude(Sketch(plane_at(o, e1, e2)).circle((0, 0), r_thru), (0, 0), depth + 0.2, cut=[body])
    h = (r_csk - r_thru) / math.tan(math.radians(angle / 2))      # cone depth
    ext = 0.1 / math.tan(math.radians(angle / 2))                 # radius growth over the 0.1 overshoot
    sk = Sketch(plane_at(center, e1, n)).poly([(r_thru, -0.1), (r_csk + ext, -0.1), (r_thru, h)])
    revolve(sk, (r_thru + 0.2, 0.1), (0, 0), (0, 1), cut=[body])
    return body


def _mid(e):
    return e["midpoint"]


@problem("11.4", 390116, features=("Extrude Boss", "Fillet", "Hole Wizard (CSK, as cut + revolve)"))
def p11_4():
    # Corner bracket of three plates meeting at the origin's corner: back
    # plate A 100 (x) x 80 (y) x 25 (z 0..25), side plate B 15 thick at
    # x -50..-35 running z 0..125, base plate C 10 thick at y -40..-30 over
    # 100 x 125. Origin at the centre of A's outer face. R10 rounds on the
    # outer edges the views show rounded (top view: the three plan corners
    # at the back and the base's front-right corner; right view: A's two
    # back edges along x and B's top-front edge; front view: A's top-right
    # edge along z and the bottom-left edge along z) — B's outer vertical
    # front edge, B's top-outer edge and the base's front/right bottom
    # edges are drawn square. R2 on the three inside corners. 6x CSK for
    # M6 flat head (SW ISO table: 6.6 through, 12.6 x 90 deg), sunk on the
    # inside faces, at the drawn positions (holes 35 apart, 25 from the
    # right edge; 25 from the top and 20 from the bottom).
    A = extrude(Sketch(front(0)).rect(-50, -40, 50, 40), (0, 0), 25)
    extrude(Sketch(right(-50)).rect(-125, -40, 0, 40), (-60, 0), 15, union=[A])
    extrude(Sketch(top(-40)).rect(-50, -125, 50, 0), (0, -60), 10, union=[A])
    t = 0.3
    def sel(pred):
        ids = edges_where(A, lambda e: pred(*_mid(e)))
        assert ids, "edge not found"
        return ids
    r10 = []
    r10 += sel(lambda x, y, z: abs(x + 50) < t and abs(z) < t)            # E1 back-left vertical
    r10 += sel(lambda x, y, z: abs(x - 50) < t and abs(z) < t)            # E2 back-right vertical
    r10 += sel(lambda x, y, z: abs(x - 50) < t and abs(z - 125) < t)      # E4 base front-right corner
    r10 += sel(lambda x, y, z: abs(y - 40) < t and abs(z) < t)            # E5 A top-back
    r10 += sel(lambda x, y, z: abs(y + 40) < t and abs(z) < t)            # E6 A bottom-back
    r10 += sel(lambda x, y, z: abs(y - 40) < t and abs(z - 125) < t)      # E7 B top-front
    r10 += sel(lambda x, y, z: abs(x + 50) < t and abs(y + 40) < t)       # E10 bottom-left along z
    r10 += sel(lambda x, y, z: abs(x - 50) < t and abs(y - 40) < t)       # E11 A top-right along z
    try:
        fillet(A, 10.0, r10)
    except Exception as e:  # noqa: BLE001
        print("  fillet R10 in one call failed, going edge by edge:", str(e)[:120])
        for pred in (lambda x, y, z: abs(x + 50) < t and abs(z) < t, lambda x, y, z: abs(x - 50) < t and abs(z) < t,
                     lambda x, y, z: abs(x - 50) < t and abs(z - 125) < t, lambda x, y, z: abs(y - 40) < t and abs(z) < t and abs(x) < 45,
                     lambda x, y, z: abs(y + 40) < t and abs(z) < t and abs(x) < 45, lambda x, y, z: abs(y - 40) < t and abs(z - 125) < t,
                     lambda x, y, z: abs(x + 50) < t and abs(y + 40) < t and 5 < z < 120, lambda x, y, z: abs(x - 50) < t and abs(y - 40) < t and 5 < z < 20):
            fillet(A, 10.0, sel(pred))
    r2 = []
    r2 += sel(lambda x, y, z: abs(y + 30) < t and abs(z - 25) < t and x > -34)   # A-C
    r2 += sel(lambda x, y, z: abs(x + 35) < t and abs(y + 30) < t and z > 26)    # B-C
    r2 += sel(lambda x, y, z: abs(x + 35) < t and abs(z - 25) < t and y > -29)   # A-B
    fillet(A, 2.0, r2)
    for c, n, d in (((-10, 15, 25), (0, 0, -1), 25), ((25, -20, 25), (0, 0, -1), 25),
                    ((-35, -20, 100), (-1, 0, 0), 15), ((-35, 15, 50), (-1, 0, 0), 15),
                    ((-10, -30, 100), (0, -1, 0), 10), ((25, -30, 50), (0, -1, 0), 10)):
        csk_hole(A, c, n, d, 3.3, 6.3)
    return A


@problem("11.5", 1827.6, features=("Extrude Boss", "Extrude Cut", "Hole Wizard (CBORE, as stacked cylinders)"))
def p11_5():
    # Cam plate 4 thick, origin at the M2.5 hole. Outline (CCW from the top):
    # top flat 8 (x -4..4) at y 18, 2-drops to the corners 5 out at y 16, a
    # 70 deg line down-left tangent to the lobe circle about (-10, 2) (its
    # radius follows from that tangency: 3.85), the lobe round to an R3
    # inside fillet onto the O14 circle about the origin, that circle to
    # (0, -7), flat to (7, -7), an R7 about (7, 0) up to (14, 0) - the 14
    # extent - vertical to the R5 (about (9, 4.17)) tangent to the 65 deg
    # line back to the corner at (9, 16). Slot 4 x (5 between centres) at
    # (0, 11); Detail B cutout = annular sector R7..R11 about the origin
    # (R9 mid), 0..50 deg, R1 corners; M2 pan-head CBORE at (-7, 6): O2.4
    # through, O4.9 x 1.6; M2.5 at the origin: O2.9 through, O5.9 x 2.0
    # (counterbore diameters measured off the sheet's rings).
    from geo115 import outline   # scripts/swpp/geo115.py (was a scratchpad file until 2026-09-16)
    segs, poly, info = outline()
    sk = Sketch(front(0))
    for s in segs:
        if s[0] == "line":
            sk.line(s[1], s[2])
        else:
            _, c, r, a0, a1 = s
            if a1 < a0:
                a0, a1 = a1, a0
            sk.arc(c, r, a0, a1)
    body = extrude(sk, (0, 14), 4)
    extrude(Sketch(front(4)).slot((-2.5, 11), (2.5, 11), 2), (0, 11), -4, cut=[body])
    # annular-sector cutout with R1 corners
    c50 = math.radians(50)
    ck = Sketch(front(4))
    fa = (math.sqrt(63), 1.0)                 # corner A: y=0 line & r7 arc
    fb = (math.sqrt(99), 1.0)                 # corner B: y=0 line & r11 arc
    tc = math.radians(50 - math.degrees(math.asin(0.1)))
    fc = (10 * math.cos(tc), 10 * math.sin(tc))   # corner C: 50deg line & r11
    td = math.radians(50 - math.degrees(math.asin(1 / 8)))
    fd = (8 * math.cos(td), 8 * math.sin(td))     # corner D: 50deg line & r7
    def deg(c, p):
        return math.degrees(math.atan2(p[1] - c[1], p[0] - c[0]))
    A_l, A_a = (fa[0], 0.0), (fa[0] * 7 / 8, fa[1] * 7 / 8)
    B_l, B_a = (fb[0], 0.0), (fb[0] * 1.1, fb[1] * 1.1)
    C_a, C_l = (fc[0] * 1.1, fc[1] * 1.1), (math.sqrt(99) * math.cos(c50), math.sqrt(99) * math.sin(c50))
    D_l, D_a = (math.sqrt(63) * math.cos(c50), math.sqrt(63) * math.sin(c50)), (fd[0] * 7 / 8, fd[1] * 7 / 8)
    ck.line(A_l, B_l)
    ck.arc(fb, 1.0, deg(fb, B_l), deg(fb, B_a))
    ck.arc((0, 0), 11.0, deg((0, 0), B_a), deg((0, 0), C_a))
    ck.arc(fc, 1.0, deg(fc, C_a), deg(fc, C_l))
    ck.line(C_l, D_l)
    ck.arc(fd, 1.0, deg(fd, D_l), deg(fd, D_a))
    ck.arc((0, 0), 7.0, deg((0, 0), A_a), deg((0, 0), D_a))
    ck.arc(fa, 1.0, deg(fa, A_a), deg(fa, A_l))
    extrude(ck, (9 * math.cos(math.radians(25)), 9 * math.sin(math.radians(25))), -4, cut=[body])
    for c, rt, rc, dc in (((-7, 6), 1.2, 2.45, 1.6), ((0, 0), 1.45, 2.95, 2.0)):
        extrude(Sketch(front(4)).circle(c, rt), c, -4, cut=[body])
        extrude(Sketch(front(4)).circle(c, rc), c, -dc, cut=[body])
    return body


@problem("11.6", 1386.5, features=("Extrude Boss", "Extrude Cut (draft)", "Hole Wizard (CSK, as cut + revolve)"))
def p11_6():
    # Keyhole bracket (front = XY, depth z 0..6, boss z 0..8). Origin at the
    # plate's top-left corner. Plate x 0..10, y -15..0; the whole underside
    # is a 30 deg face through (10, -15) lying 5 (normal) below the foot's
    # top slope; the foot: 5 along the slope from (0, -15), tip face 2,
    # back 1, a step 2 down with an R1 semicircular notch centred on it,
    # 1 back, 1 down onto the main bottom face (Detail E: 5, 2, R1, 1).
    # Boss 10 x 6 (x 9..19, y -2..4) with R2 top corners; the diagonal
    # runs from (10, -15) tangent to the top-right R2 (61.4 deg, drawn
    # ~61-63 deg); Detail B's 75 deg is the T-slot stem. The boss's front
    # 2 (z 6..8) carries a 2 x 45 chamfer at its bottom-left. T-slot: 2 wide
    # slot (R1) centres (11, 2)-(17, 2), stem 2 wide at y -1 with 75 deg
    # sides up to the slot, through the boss. Channel from the top face,
    # 14 deep, trapezoid section (see below). 2x CSK M2 flat head
    # (2.4 through, 4.4 x 90) at (5, -3) and (5, -11) from the pocket floor.
    d = (-math.cos(math.radians(30)), -math.sin(math.radians(30)))      # down the slope (toward the tip)
    n = (math.sin(math.radians(30)), -math.cos(math.radians(30)))      # perpendicular, into the body
    def P(s, t):  # slope frame: s along -d from the tip (tip s=0, plate corner s=5), t along n
        return (-4.330127 + s * 0.8660254 + t * n[0], -17.5 + s * 0.5 + t * n[1])
    A = (0.0, -15.0); B = P(0, 0); C = P(0, 2); D = P(1, 2); M = P(1, 3); E = P(1, 4); F = P(0, 4); G = P(0, 5)
    H = (10.0, -15.0)
    C2 = (17.0, 2.0)
    dist = math.hypot(C2[0] - H[0], C2[1] - H[1])
    ang = math.degrees(math.atan2(C2[1] - H[1], C2[0] - H[0])) - math.degrees(math.asin(2.0 / dist))
    L = math.sqrt(dist * dist - 4.0)
    T = (H[0] + L * math.cos(math.radians(ang)), H[1] + L * math.sin(math.radians(ang)))
    aT = math.degrees(math.atan2(T[1] - C2[1], T[0] - C2[0]))
    sk = Sketch(front(0))
    sk.line((0, 0), A).line(A, B).line(B, C).line(C, D)
    sk.arc(M, 1.0, -60, 120)
    sk.line(E, F).line(F, G).line(G, H).line(H, T)
    sk.arc(C2, 2.0, aT, 90).line((17, 4), (11, 4)).arc((11, 2), 2.0, 90, 180).line((9, 2), (9, 0)).line((9, 0), (0, 0))
    body = extrude(sk, (5, -7), 6)
    yb = -2.0
    xb = H[0] + (yb - H[1]) / math.tan(math.radians(ang))
    bs = (Sketch(front(6)).line((11, -2), (xb, -2)).line((xb, -2), T).arc(C2, 2.0, aT, 90).line((17, 4), (11, 4))
          .arc((11, 2), 2.0, 90, 180).line((9, 2), (9, 0)).line((9, 0), (11, -2)))
    extrude(bs, (14, 1), 2, union=[body])
    extrude(Sketch(front(8)).slot((11, 2), (17, 2), 1.0), (14, 2), -8, cut=[body])
    w = 2.5 / math.tan(math.radians(75))
    extrude(Sketch(front(8)).poly([(13 - w, 1.5), (15 + w, 1.5), (15, -1), (13, -1)]), (14, 0), -8, cut=[body])
    # The pocket is an open-top channel: the top view draws its trapezoid
    # section as VISIBLE lines (floor 6 wide at z = 3, mouth 7 at z = 6 -
    # the 6 / 3 callouts), the front view shows single-line top/bottom
    # walls but double-line (drafted) sides, and the left iso shows the
    # U-shaped opening in the plate's top. Cut 14 down from the top face.
    extrude(Sketch(top(0)).poly([(1.5, -6), (8.5, -6), (8, -3), (2, -3)]), (5, -4.5), -14, cut=[body])
    for c in ((5, -3, 3), (5, -11, 3)):
        csk_hole(body, c, (0, 0, -1), 3, 1.2, 2.2)
    return body


@problem("11.7", 747166.2, features=("Extrude Boss", "Extrude Cut", "Hole Wizard (CBORE, as stacked cylinders)"))
def p11_7():
    # Vee-jaw block (front = XY, z 0..100; origin at the base's bottom-left
    # corner). Base 200 x 25 x 100 with two feet 10 below (x 50..87 and
    # 112..150, full width). A full-width saddle rises from the base top at
    # x 100 to y 40 at x 140 (the 20.6 deg edge in Detail C) and stays at 40
    # to x 200 (the plan's 30 is the strip of it beside the jaw). The jaw: a
    # 30 deg ramp from (100, 25) carrying a tombstone profile 70 wide (z
    # 0..70), 50 straight (View A-A's 50) + R35 end, extruded along the
    # ramp's inward normal down into the saddle. Two
    # 10-wide slots 5 deep (Detail C) cross on the ramp: one up the slope
    # at z 30..40, one across at 45..55 along the slope. CBORE for M8 hex
    # head drawn vertical in the plan (circles, floors visible -> blind):
    # O25 spot face down to the slot-floor level, O15 x 5.5 counterbore,
    # O9 x 22 drill + point, on the slope 50 up at z 35. Lug: 40 wide (x
    # 15..55), R20 end at z 42 (centre z 62), running to the front face z
    # 100, top face sloping 15 deg from the base top at z 100 (165 deg in
    # the side view) - a wedge 15.5 high at the round end; O14 blind hole.
    from kit import plane_at, revolve
    c30, s30 = math.cos(math.radians(30)), math.sin(math.radians(30))
    body = extrude(Sketch(top(0)).rect(0, -100, 200, 0), (100, -50), 25)
    for x0, x1 in ((50, 87), (112, 150)):
        extrude(Sketch(top(0)).rect(x0, -100, x1, 0), ((x0 + x1) / 2, -50), -10, union=[body])
    # the saddle runs the full width: the plan's shade is continuous across
    # z = 70 behind the jaw and the iso shows one flat face there (the thin
    # z = 70 line in the plan is the 30 dimension's extension line)
    extrude(Sketch(front(0)).poly([(100, 25), (140, 40), (200, 40), (200, 25)]), (170, 32), 100, union=[body])
    ramp = plane_at((100, 25, 0), (c30, s30, 0), (0, 0, 1))      # u along the slope, v = z; extrudes down the normal
    tomb = (Sketch(ramp).line((0, 0), (50, 0)).arc((50, 35), 35, -90, 90).line((50, 70), (0, 70)).line((0, 70), (0, 0)))
    extrude(tomb, (25, 35), 32, union=[body])
    n = (-s30, c30, 0)
    face = plane_at((100 + 0.1 * n[0], 25 + 0.1 * n[1], 0), (c30, s30, 0), (0, 0, 1))
    extrude(Sketch(face).rect(0, 30, 90, 40), (45, 35), 5.1, cut=[body])
    extrude(Sketch(face).rect(45, -1, 55, 71), (50, 35), 5.1, cut=[body])
    # vertical hole stack at the slope point 50 up (x 143.3), z 35; the spot
    # face floor sits 5 (normal) under the ramp there, like the slot floors
    xh = 100 + 50 * c30
    y_ramp = 25 + 50 * s30
    y_sf = y_ramp - 5 / c30
    extrude(Sketch(top(80)).circle((xh, -35), 12.5), (xh, -35), -(80 - y_sf), cut=[body])
    extrude(Sketch(top(y_sf + 0.01)).circle((xh, -35), 7.5), (xh, -35), -5.51, cut=[body])
    extrude(Sketch(top(y_sf - 5.5 + 0.01)).circle((xh, -35), 4.5), (xh, -35), -22.01, cut=[body])
    # blind holes carry a 118 deg drill point (the plan shades both hole
    # floors as inclined facets, not flat): cone below the drill
    def drill_point(x, z, y_bottom, r):
        h = r / math.tan(math.radians(59))
        sk = Sketch(plane_at((x, 0, z), (1, 0, 0), (0, 1, 0))).poly([(0, y_bottom + 0.01), (r + 0.02, y_bottom + 0.01), (0, y_bottom - h)])
        revolve(sk, (r / 3, y_bottom - h / 4), (0, 0), (0, 1), cut=[body])
    drill_point(xh, 35, y_sf - 5.5 - 22, 4.5)
    # lug: tab profile on the base top, extruded 16 up, then the 15 deg slope
    lug = (Sketch(top(25)).line((15, -100), (15, -62)).arc((35, -62), 20, 0, 180).line((55, -62), (55, -100))
           .line((55, -100), (15, -100)))
    extrude(lug, (35, -80), 16, union=[body])
    t15 = math.tan(math.radians(15))
    cutp = Sketch(right(0)).poly([(-101, 25), (-30, 25 + 71 * t15), (-30, 60), (-101, 60)])
    extrude(cutp, (-60, 55), 60, cut=[body])
    # O14 hole: its floor is drawn as drill-point facets, so a blind drilled
    # hole (not a cut through the lug profile); depth undimensioned - taken
    # as 2 x D = 28 below the lug's top at the hole, plus the 118 deg point
    y_lug = 25 + 38 * t15
    extrude(Sketch(top(y_lug + 1)).circle((35, -62), 7), (35, -62), -29, cut=[body])
    drill_point(35, 62, y_lug - 28, 7)
    return body
