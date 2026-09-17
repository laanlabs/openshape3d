"""Round 6, agent A — 18.9A, 18.5A, 18.5B, 18.3, 7.23. Recipes follow
level18.py's conventions (kit operations only)."""
import math
from kit import (Sketch, front, back, top, bottom, right, left, extrude, revolve, fillet, chamfer,
                 shell, edges_where, edges_near, union, subtract, bodies, pattern, mirror, plane_at,
                 draft_face, faces, edges, move, sweep, vol)

PROBLEMS = {}


def problem(pid, volume, unit="mm", features=("Extrude Boss", "Extrude Cut")):
    def deco(fn):
        PROBLEMS[pid] = ({"volume": volume, "unit": unit, "features": list(features)}, fn)
        return fn
    return deco


@problem("7.23", 86531, features=("Extrude Boss", "Extrude Cut", "Sketch: Arcs, Offset (as arcs)"))
def p7_23():
    # Leaf spring 40 wide (z), eye centres 450 apart on y = 0. Detail A:
    # the leaf is 4 thick (the '4' at mid-span) and rolls into an eye with
    # R7 inside / R11 outside; the leaf's top face is an R3800 arc tangent
    # to both R7 circles (so its bottom R3804 is tangent to the R11s), the
    # coil runs from that tangent point round the outside to a radial end
    # face 60 deg from the vertical (210 deg on the right eye). Two O10
    # holes through the leaf 45 apart about the centre. Hand: section
    # 2178.05 mm2 x 40 - 2 x O10 x 4 = 86494 (-0.04 %).
    d = 3800 - 7
    H = math.sqrt(d * d - 225 ** 2)
    a = math.degrees(math.atan2(-H, 225))           # -86.6: tangent-point angle, right eye
    sk = Sketch(front(-20))
    sk.arc((0, H), 3800, -180 - a, a)                # top face (short arc under the centre)
    sk.arc((0, H), 3804, -180 - a, a)                # bottom face
    for ex, a0, a1, end in ((225, a, 210, 210), (-225, -30, -180 - a, -30)):
        sk.arc((ex, 0), 7, a0, a1).arc((ex, 0), 11, a0, a1)
        c, s = math.cos(math.radians(end)), math.sin(math.radians(end))
        sk.line((ex + 7 * c, 7 * s), (ex + 11 * c, 11 * s))
    body = extrude(sk, (0, H - 3802), 40)
    for x in (-22.5, 22.5):
        extrude(Sketch(top(-40)).circle((x, 0), 5), (x, 0), 50, cut=[body])
    return body


def hull_circles(sk, circles):
    """Convex outline through circles [(centre, r), ...] listed CCW round the
    hull (a circle may appear twice when it shows on both sides): tangent
    lines between consecutive circles and the arcs between them."""
    n = len(circles)
    normals = []
    for i in range(n):
        (pa, ra), (pb, rb) = circles[i], circles[(i + 1) % n]
        dx, dy = pb[0] - pa[0], pb[1] - pa[1]
        L = math.hypot(dx, dy); dx, dy = dx / L, dy / L
        phi = math.asin((ra - rb) / L)
        rx, ry = dy, -dx                                  # right of travel = outward
        normals.append((rx * math.cos(phi) + dx * math.sin(phi), ry * math.cos(phi) + dy * math.sin(phi)))
    for i in range(n):
        (pa, ra), (pb, rb) = circles[i], circles[(i + 1) % n]
        nx, ny = normals[i]
        sk.line((pa[0] + ra * nx, pa[1] + ra * ny), (pb[0] + rb * nx, pb[1] + rb * ny))
        nin = normals[i - 1]
        a0 = math.degrees(math.atan2(nin[1], nin[0])); a1 = math.degrees(math.atan2(ny, nx))
        while a1 <= a0:
            a1 += 360
        sk.arc(pa, ra, a0, a1)
    return sk


def _circle_hits(c1, r1, c2, r2):
    dx, dy = c2[0] - c1[0], c2[1] - c1[1]
    d = math.hypot(dx, dy)
    a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
    h = math.sqrt(max(r1 * r1 - a * a, 0))
    mx, my = c1[0] + a * dx / d, c1[1] + a * dy / d
    return [(mx + h * dy / d, my - h * dx / d), (mx - h * dy / d, my + h * dx / d)]


def _cls_18_9(f):
    """Face roles on the 18.9 solid (before the cavity and holes)."""
    c, n, k, A = f["centroid"], f["normal"], f["kind"], f["areaMM2"]
    r = math.hypot(c[0], c[1])
    if k == "planar" and abs(n[2]) > 0.99:
        for name, z in (("back", 0), ("front", 50), ("wallfront", 10)):
            if abs(c[2] - z) < 0.05:
                return name
        return "?"
    if k == "planar":
        for name, axis, sign, coord, val in (("floortop", 1, 1, 1, -37), ("walltop", 1, 1, 1, -10),
                                             ("bottom", 1, -1, 1, -50), ("recess", 1, -1, 1, -47),
                                             ("leftend", 0, -1, 0, -110), ("step", 0, 1, 0, -60)):
            if abs(n[axis] - sign) < 1e-3 and abs(c[coord] - val) < 0.05:
                return name
        if abs(n[2]) < 1e-3 and r < 36 and A > 150:
            return "prism"
        return "planar?"
    if k == "cylindrical":
        if A > 250 and abs(c[0] + 102.7) < 3:
            return "r20"
        if A > 500 and abs(c[0] + 21.5) < 4 and abs(c[1] + 35.4) < 4:
            return "floorarc"
        if A > 1000 and abs(c[0] + 14.5) < 4 and abs(c[1] + 42.9) < 4:
            return "botarc"
        if A > 150 and r < 36 and c[2] > 15:
            return "prism"
        return "fillet"
    if k == "other" and A > 800:
        return "sphere"
    return "fillet"


def _edges_18_9(bid, pairs):
    from kit import G
    roles = {f["index"]: _cls_18_9(f) for f in faces(bid)}
    want = [frozenset(p) for p in pairs]
    out = []
    for e in G(f"/v1/edges?body={bid}")["edges"]:
        fs = e.get("faces") or []
        if len(fs) == 2 and "lengthMM" in e and frozenset(roles[i] for i in fs) in want:
            out.append(e["index"])
    return out


def build_18_9(fillets=True):
    s15, c15 = math.sin(math.radians(15)), math.cos(math.radians(15))
    B1 = (23 * s15, 23 * c15)          # upper bolt (right of the axis)
    B2 = (-23 * s15, -23 * c15)        # lower bolt
    # cup: R35 hemisphere toward +z (the flange side), rim plane z = 0
    cup = revolve(Sketch(top(0)).line((0, 0), (35, 0)).arc((0, 0), 35, -90, 0).line((0, -35), (0, 0)),
                  (10, -10), (0, 0), (0, 1))
    # diamond boss: hull of O40 about the axis and O24 about both bolts, z 0..50
    boss = extrude(hull_circles(Sketch(front(0)), [(B1, 12), ((0, 0), 20), (B2, 12), ((0, 0), 20)]), (0, 0), 50)
    # arm: front-plane outline z 0..50 (110 to the cup axis, 40 tall with
    # R20, 3 recess from 50 in, bottom arc R45 tangent to the recess line and
    # ending under the axis on the O70 circle), channel above the 10 floor
    # cut back to the 10 wall at z 0..10
    xc = -math.sqrt(24 * 45 - 144)
    a_end = math.degrees(math.atan2(-35 + 2, -xc))
    arm_sk = (Sketch(front(0)).poly([(-110, -30), (-110, -50), (-60, -50), (-60, -47), (xc, -47)], close=False)
              .arc((xc, -2), 45, -90, a_end).poly([(0, -35), B2, (-20, -10), (-90, -10)], close=False)
              .arc((-90, -30), 20, 90, 180))
    arm = extrude(arm_sk, (-100, -40), 50)
    P = min(_circle_hits((xc, -2), 35, B2, 12), key=lambda p: p[0])
    a_p = math.degrees(math.atan2(P[1] + 2, P[0] - xc))
    ch = (Sketch(front(10)).poly([(5, -5), (5, -8), (-112, -8), (-112, -37), (xc, -37)], close=False)
          .arc((xc, -2), 35, -90, a_p).poly([P, B2, (5, -5)], close=False))
    extrude(ch, (-80, -20), 41, cut=[arm])
    body = union(cup, [boss, arm])
    if fillets == "stop":
        return body
    if fillets:
        # R3 ALL FILLETS, before the cavity and the hole-wizard holes (the
        # section shows the rim, the bores and every edge in the rim plane
        # z = 0 sharp). Groups in an order the kernel accepts; tangent
        # propagation carries each chain round the front face's outline
        # (the floor chain takes the flange rim with it, the bottom and
        # wall chains take the left end).
        for pairs in ([("sphere", "wallfront"), ("sphere", "walltop"), ("prism", "wallfront"),
                       ("floorarc", "prism"), ("floortop", "wallfront"), ("floorarc", "wallfront")],
                      [("floortop", "front"), ("floorarc", "front")],
                      [("front", "recess"), ("botarc", "front")],
                      [("wallfront", "walltop"), ("r20", "wallfront"), ("leftend", "wallfront")],
                      [("bottom", "front")]):
            ids = _edges_18_9(body, pairs)
            assert ids, pairs
            fillet(body, 3.0, ids)
    # cavity R31 and the O25 bore
    revolve(Sketch(top(0)).line((0, 0), (31, 0)).arc((0, 0), 31, -90, 0).line((0, -31), (0, 0)),
            (10, -10), (0, 0), (0, 1), cut=[body])
    extrude(Sketch(front(-1)).circle((0, 0), 12.5), (0, 0), 52, cut=[body])
    # CBORE M6 pan head: O6.6 through, O13 x 4 (section C-C)
    for b in (B1, B2):
        extrude(Sketch(front(51)).circle(b, 3.3), b, -40, cut=[body])
        extrude(Sketch(front(51)).circle(b, 6.5), b, -5, cut=[body])
    for (x, z) in ((-95, 40), (-75, 20)):
        extrude(Sketch(top(-51)).circle((x, -z), 3.3), (x, -z), 15, cut=[body])
        extrude(Sketch(top(-41)).circle((x, -z), 6.5), (x, -z), 5, cut=[body])
    return body


@problem("18.9A", 138032.3, features=("Revolve", "Extrude Boss", "Extrude Cut", "Fillet", "Hole Wizard (CBORE, as cuts)"))
def p18_9a():
    return build_18_9(fillets=True)


def _junction_edges_18_5(bid, dirs, pair):
    """Edges between two of {body (revolve), p1, p2 (ports), pipe}, faces
    told apart by geometry (face names do not survive a fillet): port
    walls are planes perpendicular to the port direction or cylinders along
    it on its side of the axis; caps, flange faces and fillets are skipped."""
    from kit import G

    def dot(a, b):
        return sum(x * y for x, y in zip(a, b))

    def role(f):
        c, n, k, A = f["centroid"], f["normal"], f["kind"], f["areaMM2"]
        if k == "planar":
            if abs(abs(n[1]) - 1) < 1e-6 or any(abs(abs(dot(n, u)) - 1) < 1e-3 for u in dirs.values()):
                return None
            for g, u in dirs.items():
                if g != "pipe" and abs(dot(n, u)) < 1e-3 and 0.25 < abs(n[1]) < 0.4 and dot(c, u) > 0:
                    return g
            return None
        if k == "cylindrical":
            if abs(abs(n[1]) - 1) < 1e-6:
                return "body" if c[1] > 13 else None
            for g, u in dirs.items():
                if abs(abs(dot(n, u)) - 1) < 1e-3 and dot(c, u) > 0:
                    return g
            return None
        return "body" if (k == "other" and A > 2000 and math.hypot(c[0], c[2]) < 20) else None

    roles = {f["index"]: role(f) for f in faces(bid)}
    hits = [e for e in G(f"/v1/edges?body={bid}")["edges"]
            if "lengthMM" in e and len(e.get("faces") or []) == 2
            and sorted(str(roles[i]) for i in e["faces"]) == sorted(pair)]
    return [e["index"] for e in sorted(hits, key=lambda e: -e["lengthMM"])]     # longest first


def build_18_5(variant="A", fillets=True):
    """Elbow housing, origin at the bottom centre, y up. 18.5A: diamond
    ports toward +z and 45 deg round to +x, O31/O21 pipe toward -x+z rising
    12 deg through the dome centre, 75 long. 18.5B: second port at -x, pipe
    O30/O20 x 60 horizontal toward +x on the ports' axis height."""
    Hd, Hp = 54.5, 58.0                    # dome centre (87 - 32.5); port axis (87 - 10 - 19)
    body = revolve(Sketch(front(0)).poly([(0, 0), (32.5, 0), (32.5, 5), (47.5, 5), (47.5, 12), (32.5, 12), (32.5, Hd)],
                                         close=False).arc((0, Hd), 32.5, 0, 90).line((0, 87), (0, 0)),
                   (20, 30), (0, 0), (0, 1))
    port_angles = (0.0, 45.0) if variant == "A" else (0.0, -90.0)

    def port_plane(theta, dist):
        t = math.radians(theta)
        u = (math.sin(t), 0.0, math.cos(t))
        return plane_at((dist * u[0], 0, dist * u[2]), (math.cos(t), 0, -math.sin(t)), (0, 1, 0)), u

    for th in port_angles:
        pl, u = port_plane(th, 0.0)
        sk = hull_circles(Sketch(pl), [((0, Hp + 19), 10), ((0, Hp), 16), ((0, Hp - 19), 10), ((0, Hp), 16)])
        extrude(sk, (0, Hp), 70, union=[body])
    if variant == "A":
        e = math.radians(12); a = math.radians(45)
        d = (-math.cos(e) * math.sin(a), math.sin(e), math.cos(e) * math.cos(a))
        xa = (math.cos(a), 0.0, math.sin(a))
        ya = (d[1] * xa[2] - d[2] * xa[1], d[2] * xa[0] - d[0] * xa[2], d[0] * xa[1] - d[1] * xa[0])
        c0 = (0, Hd, 0)
        pipe_r, bore_r, L = 15.5, 10.5, 75.0
    else:
        d = (1.0, 0.0, 0.0); xa = (0.0, 0.0, -1.0); ya = (0.0, 1.0, 0.0)
        c0 = (0, Hp, 0)
        pipe_r, bore_r, L = 15.0, 10.0, 60.0
    extrude(Sketch(plane_at(c0, xa, ya)).circle((0, 0), pipe_r), (0, 0), L, union=[body])
    if fillets == "stop":
        return body
    if fillets:
        # 5 mm ALL FILLETS AND ROUNDS = the junctions of the ports and the pipe
        # with the dome/body and with each other (port faces, pipe end, flange
        # and bores are sharp in the views and sections). Applied largest
        # first: port/port, port/pipe, pipe/body, port/body. One edge per
        # group (the longest) is enough - the blend propagates round the tangent chain. The
        # kernel refuses every port/body and port/dome blend once the first
        # groups are in (their chains run into the ports' top ridges, which
        # touch the dome crown at 87), so those are left sharp; each
        # group listed below is the set it accepted (probed 2026-09-16).
        e, a = math.radians(12), math.radians(45)
        dirs = ({"p1": (0, 0, 1), "p2": (math.sin(a), 0, math.cos(a)),
                 "pipe": (-math.cos(e) * math.sin(a), math.sin(e), math.cos(e) * math.cos(a))}
                if variant == "A" else {"p1": (0, 0, 1), "p2": (-1, 0, 0), "pipe": (1, 0, 0)})
        groups = [("p1", "p2"), ("p1", "pipe")] if variant == "A" else [("body", "pipe")]
        for pair in groups:
            ids = _junction_edges_18_5(body, dirs, pair)
            assert ids, pair
            fillet(body, 5.0, ids[:1])
    # cavity: O53 bore up to the dome centre, R26.5 dome
    revolve(Sketch(front(0)).poly([(0, -1), (26.5, -1), (26.5, Hd)], close=False).arc((0, Hd), 26.5, 0, 90)
            .line((0, Hd + 26.5), (0, -1)), (10, 20), (0, 0), (0, 1), cut=[body])
    for th in port_angles:
        pl, u = port_plane(th, 70.5)
        extrude(Sketch(pl).circle((0, Hp), 7.5), (0, Hp), -50, cut=[body])
        for yy in (Hp + 19, Hp - 19):
            extrude(Sketch(pl).circle((0, yy), 5), (0, yy), -25.5, cut=[body])
    end = tuple(c0[i] + (L + 0.5) * d[i] for i in range(3))
    extrude(Sketch(plane_at(end, xa, ya)).circle((0, 0), bore_r), (0, 0), -(L + 0.5), cut=[body])
    return body


@problem("18.5A", 225009.5, features=("Revolve", "Extrude Boss", "Extrude Cut", "Plane (angled sketch planes)", "Pattern (as recipe)", "Fillet"))
def p18_5a():
    return build_18_5("A", fillets=True)


@problem("18.5B", 218746.1, features=("Revolve", "Extrude Boss", "Extrude Cut", "Editing (rebuilt with the 18.5B changes)", "Fillet"))
def p18_5b():
    return build_18_5("B", fillets=True)


def _dogbone(sk, r, R, yc):
    """Outline of two radius-r bosses at x = +-30 joined by radius-R arcs
    centred at (0, +-yc) (tangent when yc = sqrt((r+R)^2 - 30^2))."""
    t = math.degrees(math.atan2(yc, 30))                # boss angle of the tangent point
    return (sk.arc((30, 0), r, -(180 - t), 180 - t).arc((0, yc), R, -180 + t, -t)
            .arc((-30, 0), r, t, 360 - t).arc((0, -yc), R, t, 180 - t))


def _tube_junction_edge(bid, axis_y, positive_z):
    """The longest edge where 18.3's O26 tube (axis along z at height axis_y)
    meets a waist wall, on the z > 0 or the z < 0 side."""
    side = [e for e in edges(bid)
            if abs(math.hypot(e["midpoint"][0], e["midpoint"][1] - axis_y) - 13) < 0.05
            and abs(abs(e["midpoint"][2]) - 20) > 0.05
            and (e["midpoint"][2] > 0) == positive_z]
    return max(side, key=lambda e: e["lengthMM"])["index"]


def build_18_3(stage="full"):
    """Link: two O40 bosses 60 apart joined by R40 arcs tangent to both,
    30 tall, origin at the bottom centre (y up, the link along x), R6 round
    on the top outline; O26 cross tube along z, 40 long, tangent to the top
    (axis 17 up). 3 SHELL open at the bottom and both tube ends, built as
    explicit cuts (feature.shell refuses this body): the 3-offset outline
    (R17 bosses, R43 arcs, same centres) 27 up with the R6's offset R3 at its
    top edge, and the O20 bore through the tube. O18 holes through the top
    at the boss centres (Section B-B: no bosses round them). R3 where the
    tube meets the waist walls.

    OCCT cannot end a blend where it vanishes, and the R3 vanishes where the
    tube touches the top face: drawn tangent, every order is refused
    ("TopoDS_Vertex hasn't gp_Pnt"). So the tube sits 0.001 mm lower than
    drawn. The blend converges as the gap closes (per side: +238.247 mm3 at
    2 mm, +227.67 at 0.2, +226.474 at 0.01, +226.418 at 0.001; 2026-09-16)."""
    yc = math.sqrt(60 ** 2 - 30 ** 2)
    axis = 17 - 0.001
    body = extrude(_dogbone(Sketch(top(0)), 20, 40, yc), (0, 0), 30)
    fillet(body, 6.0, edges_where(body, lambda e: abs(e["midpoint"][1] - 30) < 1e-3))
    extrude(Sketch(front(-20)).circle((0, axis), 13), (0, axis), 40, union=[body])
    if stage == "outer":
        return body
    # one edge per side: the blend runs round that side's tangent chain
    for positive_z in (True, False):
        fillet(body, 3.0, [_tube_junction_edge(body, axis, positive_z)])
    cav = extrude(_dogbone(Sketch(top(-1)), 17, 43, yc), (0, 0), 28, new_body=True)
    fillet(cav, 3.0, edges_where(cav, lambda e: abs(e["midpoint"][1] - 27) < 1e-3))
    subtract(body, [cav])
    extrude(Sketch(front(-21)).circle((0, axis), 10), (0, axis), 42, cut=[body])
    for x in (-30, 30):
        extrude(Sketch(top(20)).circle((x, 0), 9), (x, 0), 15, cut=[body])
    return body


@problem("18.3", 27786.2, features=("Extrude Boss", "Fillet", "Shell (as explicit cuts)", "Hole Wizard (as cuts)", "Mirror (symmetric sketch)"))
def p18_3():
    return build_18_3()
