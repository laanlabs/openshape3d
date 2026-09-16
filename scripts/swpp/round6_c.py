"""Round 6, agent C — Level 18 CSWP sheets (18.22, 18.15, 18.10, …).
Recipes follow level18.py's conventions: front = world XY (x right, y up,
z toward the viewer), top = XZ with sketch v = -z, right = YZ with u = -z."""
import math
from kit import (Sketch, front, back, top, bottom, right, left, extrude, revolve, fillet, chamfer,
                 shell, edges_where, edges_near, union, subtract, bodies, pattern, mirror, plane_at,
                 draft_face, faces, vol)

PROBLEMS = {}


def problem(pid, volume, unit="mm", features=("Extrude Boss", "Extrude Cut"), configs=None):
    def deco(fn):
        meta = {"volume": volume, "unit": unit, "features": list(features)}
        if configs:
            meta["configs"] = list(configs)
        PROBLEMS[pid] = (meta, fn)
        return fn
    return deco


def _cyl_cut(body, plane_y, c, r, depth):
    """Round cut on a top(plane_y) sketch at plan point c = (x, v=-z);
    depth < 0 goes down (-y), > 0 up."""
    extrude(Sketch(top(plane_y)).circle(c, r), c, depth, cut=[body])


@problem("18.22", 230587.9, features=("Extrude Boss", "Extrude Cut (cavity, as shell)", "Fillet",
                                       "Fillet (lug roots, as sketch)", "Chamfer",
                                       "Hole Wizard (CBORE, as stacked cylinders)"))
def p18_22():
    # Square tube 300 long (x -150..150), 30 deep (z -15..15), 35 tall
    # (y 0..35; origin at the bottom face's centre), R3 outer corners, 2 TYP
    # wall (inner 26 x 31, R1 corners — the shell of the R3 box), open both
    # ends (the right view sees straight through, so the lugs do not fill
    # the cavity). Two lugs at x = -90 / 80 (60 and 230 from the left end:
    # 170 apart, 70 from the right end): an R15 obround with its centres
    # 12 in front of the tube's front face (the M10 hole) and 9 behind it
    # (the bottom view's 21), from the tube top down 40 below the tube.
    # Four O22 x 15 bosses on the tube bottom's centreline at 24 + 82 k
    # from the left end (82 pitch, 30 from the right end), 2 x 45 bottom
    # chamfer. R3 ALL FILLETS: boss roots (app fillet), the lug/front-face
    # roots (sketch rounds in the lug outline) and the lug/bottom-face roots
    # (revolve + extrude — the app's fillet refuses those edges where they
    # run into the tube's R3 corners). CBORE M10 hex bolt from the top:
    # O11 through, O21 x 6.4; CBORE M5 hex bolt from the boss bottoms:
    # O5.5 into the cavity, O12 x 3.5. The counterbore diameters are
    # measured off the plan rings (O21.0-21.3, O12.1; the O11/O5.5 holes and
    # O22/O18 boss rings measure true); depths are not on the sheet and are
    # taken as the ISO 4014 head heights k (6.4, 3.5).
    lugs = (-90.0, 80.0)
    body = extrude(Sketch(right(-150)).rounded_poly([(-15, 0), (15, 0), (15, 35), (-15, 35)], 3), (0, 10), 300)
    for xc in lugs:
        extrude(Sketch(top(0)).slot((xc, -6), (xc, -27), 15), (xc, -16), -40, union=[body])
        up = (Sketch(top(0)).line((xc - 18, 0), (xc - 18, -15)).arc((xc - 18, -18), 3, 0, 90)
              .line((xc - 15, -18), (xc - 15, -27)).arc((xc, -27), 15, 180, 360)
              .line((xc + 15, -27), (xc + 15, -18)).arc((xc + 18, -18), 3, 90, 180)
              .line((xc + 18, -15), (xc + 18, 0)).line((xc + 18, 0), (xc - 18, 0)))
        extrude(up, (xc, -30), 35, union=[body])
        # lug/bottom-face root round: a half ring about the inner centre
        # (z = 6) swept from +x through -z to -x, and the straight runs on
        # the two flats from z = 6 to the tube's bottom corner at z = 12
        ring = Sketch(plane_at((xc, 0, 6), (1, 0, 0), (0, 1, 0)))
        ring.line((15, 0), (18, 0)).arc((18, -3), 3, 90, 180).line((15, -3), (15, 0))
        revolve(ring, (15.4, -0.4), (0, 0), (0, 1), angle=180.0, union=[body])   # +x -> -z -> -x
        for sx in (-1, 1):
            x0 = xc + sx * 15
            prof = Sketch(front(6)).line((x0, 0), (x0 + sx * 3, 0)).line((x0, -3), (x0, 0))
            prof.arc((x0 + sx * 3, -3), 3, 90, 180) if sx > 0 else prof.arc((x0 - 3, -3), 3, 0, 90)
            extrude(prof, (x0 + sx * 0.4, -0.4), 6, union=[body])
    for bx in (-126.0, -44.0, 38.0, 120.0):
        extrude(Sketch(top(0)).circle((bx, 0), 11), (bx, 0), -15, union=[body])
    fillet(body, 3.0, edges_where(body, lambda e: abs(e["midpoint"][1]) < 0.3 and 60 < e["lengthMM"] < 72))
    chamfer(body, 2.0, edges_where(body, lambda e: abs(e["midpoint"][1] + 15) < 0.3 and 60 < e["lengthMM"] < 72))
    cav = Sketch(right(-151)).rounded_poly([(-13, 2), (13, 2), (13, 33), (-13, 33)], 1)
    extrude(cav, (0, 10), 302, cut=[body])
    for xc in lugs:
        _cyl_cut(body, 36, (xc, -27), 5.5, -77)
        _cyl_cut(body, 36, (xc, -27), 10.5, -(1 + 6.4))
    for bx in (-126.0, -44.0, 38.0, 120.0):
        _cyl_cut(body, -16, (bx, 0), 2.75, 1 + 15 + 2 + 1)
        _cyl_cut(body, -16, (bx, 0), 6.0, 1 + 3.5)
    return body


@problem("18.15", 3447594.2, features=("Extrude Boss", "Extrude Cut", "Rib (as extrude)",
                                        "Hole Wizard (CBORE / CSK / straight, as cuts + revolve)"))
def p18_15():
    # Front view = the C face (world XY, z toward the viewer), origin at the
    # C centre on the front face, body z 0..-140. C: O204 about the origin,
    # flat top at y = 82, an 80-wide slot open to -x ending in R40 about the
    # origin; the back 20 (z -120..-140) has the slot 10 wider each side
    # (R50 end: the back view's second U with its 10, the left view's 20
    # band, the top view's 20 notch). Lug 55 wide (x +-27.5) x 50 thick
    # (z -10..-60) from the flat up to 170 with an R25 top (centre y 145),
    # CBORE M14 hex bolt along x (O15.5 through, O26 x 8.8 from +x; the
    # right view shows the rings, the left view the plain hole). Rib 12
    # thick on x = 0 behind the lug: 48 tall at z = -60 sloping to the flat
    # at z = -130 (10 short of the back). Tail 70 thick (z -10..-80): left
    # edge x = -27.5 (in line with the lug), R38 end about (0, -146) with
    # a O25 hole, right edge the common tangent of the R38 and O204 circles.
    # Detail A: 2 x CSK M10 flat head (O11 through, O20 x 90 deg) on the
    # O140 bolt circle at +-58 deg, 2 x O13.5 x 40 blind at x = -20 on the
    # same rows (y = +-70 sin 58). Counterbore/countersink diameters are
    # measured (O25.9 / O19.1-19.7); cbore depth = M14 head height 8.8.
    from level11 import csk_hole
    R = 102.0
    def c_profile(z, w):
        xs = math.sqrt(R * R - w * w)
        a_lo = 180 + math.degrees(math.asin(w / R))
        a_hi = 180 - math.degrees(math.asin(w / R))
        a_top = math.degrees(math.asin(82 / R))
        xt = math.sqrt(R * R - 82 * 82)
        return (Sketch(front(z)).arc((0, 0), R, a_lo, 360 + a_top).line((xt, 82), (-xt, 82))
                .arc((0, 0), R, 180 - a_top, a_hi).line((-xs, w), (0, w)).arc((0, 0), w, -90, 90)
                .line((0, -w), (-xs, -w)))
    body = extrude(c_profile(0, 40), (70, 0), -120)
    extrude(c_profile(-120, 50), (75, 0), -20, union=[body])
    lug = (Sketch(right(-27.5)).line((10, 70), (60, 70)).line((60, 70), (60, 145)).arc((35, 145), 25, 0, 180)
           .line((10, 145), (10, 70)))
    extrude(lug, (35, 100), 55, union=[body])
    rib = Sketch(right(-6)).poly([(58, 75), (58, 130), (60, 130), (130, 82), (130, 75)])
    extrude(rib, (80, 80), 12, union=[body])
    s = -64 / 146; c = math.sqrt(1 - s * s)
    TA = (R * c, R * s); TB = (38 * c, -146 + 38 * s)
    y2 = -146 + math.sqrt(38 * 38 - 27.5 * 27.5)
    a2 = math.degrees(math.atan2(y2 + 146, -27.5))
    tail = (Sketch(front(-10)).line((-27.5, -60), (-27.5, y2)).arc((0, -146), 38, a2, 360 + math.degrees(math.asin(s)))
            .line(TB, TA).line(TA, (-27.5, -60)))
    extrude(tail, (0, -130), -70, union=[body])
    extrude(Sketch(front(1)).circle((0, -146), 12.5), (0, -146), -100, cut=[body])
    extrude(Sketch(right(28.5)).circle((35, 145), 7.75), (35, 145), -57, cut=[body])
    extrude(Sketch(right(28.5)).circle((35, 145), 13.0), (35, 145), -(1 + 8.8), cut=[body])
    yb = 70 * math.sin(math.radians(58)); xb = 70 * math.cos(math.radians(58))
    for sy in (1, -1):
        csk_hole(body, (xb, sy * yb, 0), (0, 0, -1), 140, 5.5, 10.0)
        extrude(Sketch(front(1)).circle((-20, sy * yb), 6.75), (-20, sy * yb), -41, cut=[body])
    return body


@problem("18.10", 50540.5, features=("Extrude Boss", "Extrude Cut", "Mirror (as second cut)",
                                       "Fillet (sketch R3)", "Full Round Fillet (as cut)"))
def p18_10():
    # Clevis, front view = world XY, 30 thick (z -15..15), origin at the O15
    # slot end. Outer: O55 head about the origin, flanks 30 deg off vertical
    # tangent to it (tangent at y = -13.75), R20 TYP into the legs' outer
    # edges x = +-15 (the side view's tangent lines at -13.5/-24.2/-34.3
    # match -13.75/-24.38/-34.38), legs down to y = -65; a 15-wide slot up
    # to the R7.5 end at the origin. Section A-A: U-grooves 12 deep on both
    # faces (6 TYP web), 10 wide between R12.5 and R22.5 (5 walls): the
    # R22.5 arc runs on below y = 0 until it meets the groove's inner lines
    # x = +-12.5, R3 TYP in those tips (bottom at y = -14.8, measured
    # -14.7). Legs: full round R15 in the side view about y = -50 with a
    # O20 hole along x (5 wall).
    c30, s30 = math.cos(math.radians(30)), math.sin(math.radians(30))
    T = (27.5 * c30, -27.5 * s30)
    cy = 2 * (35 * c30 - 47.5)
    F = (35 - 20 * c30, cy + 20 * s30)
    sk = Sketch(front(-15)).arc((0, 0), 27.5, -30, 210)
    for sx in (1, -1):
        sk.line((sx * T[0], T[1]), (sx * F[0], F[1]))
        sk.arc((sx * 35, cy), 20, 150, 180) if sx > 0 else sk.arc((-35, cy), 20, 0, 30)
        sk.line((sx * 15, cy), (sx * 15, -65)).line((sx * 15, -65), (sx * 7.5, -65)).line((sx * 7.5, -65), (sx * 7.5, 0))
    sk.arc((0, 0), 7.5, 0, 180)
    body = extrude(sk, (11, -40), 30)
    yc = -math.sqrt(19.5 ** 2 - 15.5 ** 2)
    tp = (15.5 * 22.5 / 19.5, yc * 22.5 / 19.5)
    a_t = math.degrees(math.atan2(tp[1], tp[0]))
    a_f = math.degrees(math.atan2(tp[1] - yc, tp[0] - 15.5))
    for z, d in ((15, -12), (-15, 12)):
        g = (Sketch(front(z)).arc((0, 0), 22.5, a_t, 180 - a_t).arc((0, 0), 12.5, 0, 180)
             .line((12.5, 0), (12.5, yc)).line((-12.5, 0), (-12.5, yc))
             .arc((15.5, yc), 3, 180, 360 + a_f).arc((-15.5, yc), 3, 180 - a_f, 360))
        extrude(g, (0, 17.5), d, cut=[body])
    rnd = (Sketch(right(-16)).line((-16, -50), (-15, -50)).arc((0, -50), 15, 180, 360).line((15, -50), (16, -50))
           .line((16, -50), (16, -66)).line((16, -66), (-16, -66)).line((-16, -66), (-16, -50)))
    extrude(rnd, (-15.5, -65.5), 32, cut=[body])
    extrude(Sketch(right(-16)).circle((0, -50), 10), (0, -50), 32, cut=[body])
    return body
