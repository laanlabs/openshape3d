"""Level 4 — Extrude Cut & Fillet/Chamfer (70 problems)."""
import math
from kit import Sketch, front, top, bottom, right, left, back, plane_at, extrude, revolve, fillet, chamfer, edges_where, edges_near, edges_along, union, subtract, move, mirror, pattern, X

PROBLEMS = {}


def problem(pid, volume, unit="mm", features=("Extrude Boss", "Extrude Cut")):
    def deco(fn):
        PROBLEMS[pid] = ({"volume": volume, "unit": unit, "features": list(features)}, fn)
        return fn
    return deco


@problem("4.41", 107609, features=("Extrude Boss", "Sketch: Slot", "Extrude Cut", "Fillet and Chamfer"))
def p4_41():
    # Ø62 tube, 5 wall, 80 long (axis y) with two 12-thick mid-plane lugs:
    # 44-wide tabs to R22 ends 55 out, Ø20 holes; R2 on the lug edges.
    tube = extrude(Sketch(top(-40)).circle((0, 0), 31).circle((0, 0), 26), (28, 0), 80)
    for sgn in (1, -1):
        cx = sgn * 55
        lug = (Sketch(top(-6)).line((0, 22), (cx, 22)).line((cx, -22), (0, -22))
               .line((0, -22), (0, 22))
               .arc((cx, 0), 22, -90 if sgn > 0 else 90, 90 if sgn > 0 else 270)
               .circle((cx, 0), 10))
        extrude(lug, (sgn * 40, 15), 12, union=[tube])
    # keep the bore clear: cut it again through everything
    extrude(Sketch(top(-41)).circle((0, 0), 26), (0, 0), 82, cut=[tube])
    # R2 on the lugs' outline edges (top and bottom faces, outside the tube)
    ids = edges_where(tube, lambda e: abs(abs(e["midpoint"][1]) - 6) < 0.5
                      and math.hypot(e["midpoint"][0], e["midpoint"][2]) > 31.5
                      and e["lengthMM"] > 5)
    fillet(tube, 2.0, ids)
    return tube


@problem("4.28", 412728)
def p4_28():
    # L-block 150 long, 75 deep: a 25-thick top bar (y 50..75) and a 65-wide
    # leg (x 85..150) down to y = 0; Ø25 hole through the bar 35 in from
    # the left; a 40 × 50 × 50 notch out of the leg's far end.
    body = extrude(Sketch(front(0)).poly([(0, 50), (0, 75), (150, 75), (150, 0), (85, 0), (85, 50)]),
                   (100, 60), 75)
    extrude(Sketch(top(50)).circle((35, -37.5), 12.5), (35, -37.5), 25, cut=[body])
    extrude(Sketch(top(-1)).rect(110, -75, 150, -25), (130, -50), 51, cut=[body])
    return body


@problem("4.25", 17428, features=("Extrude Boss", "Extrude Cut", "Fillet and Chamfer"))
def p4_25():
    # Clevis pin: Ø11 shank 48 tall; a 26 × 16 head above it with an R9
    # round top about the Ø8 hole at y = 79, a Ø6 hole at (7, 64), the
    # sides running tangent from (±13, 64) up to the round; 1 × 45° chamfer
    # on the shank's end.
    P = (13.0, 64.0); C = (0.0, 79.0); R = 9.0
    d = math.hypot(P[0] - C[0], P[1] - C[1])
    base = math.atan2(C[1] - P[1], C[0] - P[0])
    off = math.asin(R / d)
    L = math.sqrt(d * d - R * R)
    ang = base - off                       # tangent touching the circle's right side
    T = (P[0] + L * math.cos(ang), P[1] + L * math.sin(ang))
    aT = math.degrees(math.atan2(T[1] - C[1], T[0] - C[0]))
    head = (Sketch(front(-8)).line((-13, 48), (13, 48)).line((13, 48), P).line(P, T)
            .arc(C, R, aT, 180 - aT).line((-T[0], T[1]), (-13, 64)).line((-13, 64), (-13, 48))
            .circle((0, 79), 4).circle((7, 64), 3))
    body = extrude(head, (0, 55), 16)
    extrude(Sketch(top(0)).circle((0, 0), 5.5), (0, 0), 48.5, union=[body])
    chamfer(body, 1.0, edges_where(body, lambda e: abs(e["midpoint"][1]) < 0.5 and abs(e["lengthMM"] - 2 * math.pi * 5.5) < 1))
    return body


@problem("4.38", 152280, features=("Extrude Boss", "Extrude Cut"))
def p4_38():
    # L-bracket 23 thick: 96-wide arm 52 tall at the top of a 28-wide,
    # 150-tall leg; R23 outer / R9 inner corners; Ø12 through the arm at
    # (23, 124) with a Ø30 × 12 counterbore from the front, a 20 × 16
    # rectangular cut off the arm's end overlapping it; Ø6 across the leg
    # 12 up from the bottom.
    prof = Sketch(front(0)).poly([(0, 98), (0, 150), (96, 150), (96, 0), (68, 0), (68, 98)])
    body = extrude(prof, (80, 100), 23)
    fillet(body, 23.0, edges_where(body, lambda e: abs(e["midpoint"][0] - 96) < 0.5 and abs(e["midpoint"][1] - 150) < 0.5))
    fillet(body, 9.0, edges_where(body, lambda e: abs(e["midpoint"][0] - 68) < 0.5 and abs(e["midpoint"][1] - 98) < 0.5))
    extrude(Sketch(front(-1)).circle((23, 124), 6), (23, 124), 25, cut=[body])
    extrude(Sketch(front(23)).circle((23, 124), 15), (23, 124), -12, cut=[body])
    extrude(Sketch(front(23)).rect(-1, 97, 20, 151), (10, 120), -16, cut=[body])
    extrude(Sketch(right(60)).circle((-11.5, 12), 3), (-11.5, 12), 40, cut=[body])
    return body


@problem("4.65", 90519)
def p4_65():
    # 90 × 40 × 35 block: a Ø25 half-round channel along the top (axis
    # along x on the top edge's centreline), a Ø25 half-round notch across
    # the bottom front-to-back, two Ø10 vertical holes 64 apart.
    # top plane v = -z: rect v ∈ [-40, 0] puts the block at z ∈ [0, 40]
    body = extrude(Sketch(top(0)).rect(0, -40, 90, 0), (45, -20), 35)
    extrude(Sketch(right(-1)).circle((-20, 35), 12.5), (-20, 35), 92, cut=[body])    # channel along x at z = 20
    extrude(Sketch(front(-1)).circle((45, 0), 12.5), (45, 0), 42, cut=[body])        # notch along z at the bottom
    for x in (13, 77):
        extrude(Sketch(top(-1)).circle((x, -20), 5), (x, -20), 37, cut=[body])
    return body


@problem("4.44", 90831, features=("Extrude Boss", "Sketch: Offset", "Sketch: Trim", "Sketch: Convert", "Extrude Cut", "Fillet and Chamfer"))
def p4_44():
    # Fork: an 11-thick stem 30 wide with an R15 round bottom about the
    # origin and Ø13 holes at y = 0 and 30, rising to a 64 × 35 × 48 head at
    # y = 64 (R10 at the junction); two 11-wide prongs 18 tall on the head
    # with a Ø24 half-round across their tops 22 in from the back.
    head = extrude(Sketch(front(0)).rect(-32, 64, 32, 99), (0, 80), 48)
    extrude(Sketch(front(-1)).rect(-21, 81, 21, 100), (0, 90), 50, cut=[head])
    extrude(Sketch(right(-33)).circle((-22, 99), 12), (-22, 99), 66, cut=[head])
    stem = (Sketch(front(0)).line((-15, 0), (-15, 64)).line((-15, 64), (15, 64)).line((15, 64), (15, 0))
            .arc((0, 0), 15, 180, 360).circle((0, 0), 6.5).circle((0, 30), 6.5))
    extrude(stem, (0, 45), 11, union=[head])
    fillet(head, 10.0, edges_where(head, lambda e: abs(abs(e["midpoint"][0]) - 15) < 0.5
                                   and abs(e["midpoint"][1] - 64) < 0.5 and abs(e["lengthMM"] - 11) < 0.5))
    return head


@problem("4.45", 27348, features=("Extrude Boss", "Sketch: Offset", "Extrude Cut", "Fillet and Chamfer"))
def p4_45():
    # Bent handle, 21 wide × 7 thick: an arm along x to an R20 eye (Ø18)
    # 85 from the leg's outer face, a 90° bend (R14 outside, R7 inside),
    # a leg down to a second R20 eye 55 below the arm's top face.
    xj = 85 - math.sqrt(400 - 10.5 ** 2)            # strip edges meet the eye's circle
    aj = math.degrees(math.atan2(10.5, xj - 85))    # ≈ 148.3°
    arm = (Sketch(top(-7)).line((14, 10.5), (xj, 10.5)).arc((85, 0), 20, -aj, aj)
           .line((xj, -10.5), (14, -10.5)).line((14, -10.5), (14, 10.5)).circle((85, 0), 9))
    body = extrude(arm, (40, 0), 7)
    bend = Sketch(front(-10.5)).arc((14, -14), 14, 90, 180).arc((14, -14), 7, 90, 180) \
        .line((0, -14), (7, -14)).line((14, -7), (14, 0))
    extrude(bend, (14 - 10.5 * math.cos(math.radians(45)), -14 + 10.5 * math.sin(math.radians(45))), 21, union=[body])
    vj = -55 + math.sqrt(400 - 10.5 ** 2)           # strip edges meet the lower eye
    bj = math.degrees(math.atan2(vj + 55, 10.5))    # ≈ 58.3°
    leg = (Sketch(right(0)).line((10.5, -14), (10.5, vj)).arc((0, -55), 20, 180 - bj, 360 + bj)
           .line((-10.5, vj), (-10.5, -14)).line((-10.5, -14), (10.5, -14)).circle((0, -55), 9))
    extrude(leg, (0, -30), 7, union=[body])
    return body


@problem("4.69", 11120, features=("Extrude Boss", "Sketch: Polygon", "Extrude Cut"))
def p4_69():
    # Hex prism 19 across flats (flats left/right), 40 tall at the left
    # edge, the top cut by a plane falling 25° to the right.
    hexp = extrude(Sketch(top(0)).polygon_flats((0, 0), 19, 6, rotation_deg=90), (0, 0), 40)
    t = math.tan(math.radians(25))
    cutter = Sketch(front(-20)).poly([(-20, 40 + 10.5 * t), (20, 40 - 29.5 * t), (20, 60), (-20, 60)])
    extrude(cutter, (0, 55), 40, cut=[hexp])
    return hexp


@problem("4.10", 65203)
def p4_10():
    # U-bracket 39 deep: inner R23 semicircle about the origin with vertical
    # inner walls at ±23 rising to y = 16; outer walls at ±32.5 from y = 16
    # down to −16.5, 45° to a 26-wide flat bottom at −36; 6-thick flanges
    # (y 10..16) out to ±55 with four Ø8 holes at (±40, ±9.5).
    sk = (Sketch(front(-19.5))
          .poly([(-55, 16), (-55, 10), (-32.5, 10), (-32.5, -16.5), (-13, -36), (13, -36),
                 (32.5, -16.5), (32.5, 10), (55, 10), (55, 16), (23, 16), (23, 0)], close=False)
          .arc((0, 0), 23, 180, 360)
          .line((-23, 0), (-23, 16)).line((-23, 16), (-55, 16)))
    body = extrude(sk, (-28, 0), 39)
    holes = Sketch(top(10))
    for x in (-40, 40):
        for v in (-9.5, 9.5):
            holes.circle((x, v), 4)
    for x in (-40, 40):
        for v in (-9.5, 9.5):
            extrude(Sketch(top(10)).circle((x, v), 4), (x, v), 6, cut=[body])
    return body


@problem("4.8", 258631, features=("Extrude Boss", "Extrude Cut"))
def p4_8():
    # Base 190 × 50 × 12 with 25 × 20 corner chamfers on the far edge and
    # 2 × Ø15 at 155 apart, 18 in from the near edge; two uprights 18 thick,
    # 55 apart, 50 deep, with R40 tops about Ø16 holes 58 above the base's
    # bottom (top at 98); an 8 rib between them 28 above the base, centred
    # on the base holes' line. 103 759 + 142 520 + 12 320 = 258 599.
    import math
    base = Sketch(top(0)).poly([(-95, -20), (-70, 0), (70, 0), (95, -20), (95, -50), (-95, -50)])
    base.circle((-77.5, -32), 7.5).circle((77.5, -32), 7.5)
    body = extrude(base, (0, -25), 12)
    ys = 58 + math.sqrt(40 ** 2 - 25 ** 2)          # where the R40 top meets the sides
    a0 = math.degrees(math.atan2(ys - 58, 25))
    for x0 in (27.5, -45.5):
        up = (Sketch(right(x0)).line((0, 6), (0, ys)).arc((-25, 58), 40, a0, 180 - a0)
              .line((-50, ys), (-50, 6)).line((-50, 6), (0, 6)).circle((-25, 58), 8))
        extrude(up, (-25, 30), 18, union=[body])
    extrude(Sketch(top(12)).rect(-27.5, -36, 27.5, -28), (0, -32), 28, union=[body])
    return body


@problem("4.15", 118919, features=("Extrude Boss", "Extrude Cut", "Fillet and Chamfer"))
def p4_15():
    # 65 × 41 × 80 block. Section shape S (floor 13 to x = 16, an R60 arc
    # centred on the left edge up to the 35° slope that starts at x = 44,
    # 5 × 45° chamfer top-left) runs the full 80; the full profile P (top
    # at 41, Ø10 at (12, 31)) stands as a 10 wall at the far end (z −40..−30)
    # and a 4 wall at z 30..34 behind a 6 front strip. A 22-wide channel 5
    # deep along the bottom and a 22 × 5 full-height slot in the right end.
    t = math.tan(math.radians(35))
    yR = 41 - 21 * t
    yc = 13 + math.sqrt(3600 - 256)                  # arc centre (0, yc)
    lo, hi = 44.0, 65.0
    for _ in range(80):
        m = (lo + hi) / 2
        if yc - math.sqrt(3600 - m * m) > 41 - (m - 44) * t:
            hi = m
        else:
            lo = m
    xi = lo; yi = 41 - (xi - 44) * t
    aI = math.degrees(math.atan2(yi - yc, xi)); a16 = math.degrees(math.atan2(13 - yc, 16))
    S = (Sketch(front(-40)).poly([(0, 0), (65, 0), (65, yR), (xi, yi)], close=False)
         .arc((0, yc), 60, a16, aI).line((16, 13), (0, 13)).line((0, 13), (0, 0)))
    body = extrude(S, (30, 5), 80)
    for z0, th in ((-40, 10), (30, 4)):
        P = Sketch(front(z0)).poly([(0, 0), (65, 0), (65, yR), (44, 41), (5, 41), (0, 36)])
        extrude(P, (20, 20), th, union=[body])
    extrude(Sketch(front(-41)).circle((12, 31), 5), (12, 31), 82, cut=[body])
    extrude(Sketch(right(-1)).rect(-11, -1, 11, 5), (0, 2), 67, cut=[body])
    extrude(Sketch(bottom(42)).rect(60, -11, 66, 11), (63, 0), 43, cut=[body])
    return body


@problem("4.16", 164805, features=("Extrude Boss", "Extrude Cut", "Fillet and Chamfer"))
def p4_16():
    # Lever: R21 eye (Ø18) about the origin, 36 wide (5 step on the near
    # side, to x = 21); 41-wide arm with its top at 21 to x = 50, a 55°
    # slope down to the block top above x = 65 (y = 21 − 15·tan55), block
    # 45 long × 32 tall, R10 between the arm's bottom and the block's back
    # face; Ø12 vertical holes at x = 36 and 86 on the centreline, a 12 × 7
    # slot along the block's bottom, 3 × 45° chamfers on the block's end
    # corners and the arm's top near edge.
    y0 = 21 - 15 * math.tan(math.radians(55))
    eye = (Sketch(front(-20.5)).line((0, 21), (21, 21)).line((21, 21), (21, -21)).line((21, -21), (0, -21))
           .arc((0, 0), 21, 90, 270).circle((0, 0), 9))
    body = extrude(eye, (14, 0), 36)
    arm = (Sketch(front(-20.5)).poly([(21, 21), (50, 21), (65, y0), (110, y0), (110, y0 - 32), (65, y0 - 32), (65, -31)], close=False)
           .arc((55, -31), 10, 0, 90).line((55, -21), (21, -21)).line((21, -21), (21, 21)))
    extrude(arm, (40, 0), 41, union=[body])
    for x in (36, 86):
        extrude(Sketch(bottom(30)).circle((x, 0), 6), (x, 0), 70, cut=[body])
    extrude(Sketch(left(111)).rect(-6, y0 - 33, 6, y0 - 25), (0, y0 - 29), 61, cut=[body])
    chamfer(body, 3.0, edges_where(body, lambda e: abs(e["midpoint"][0] - 110) < 0.5 and abs(abs(e["midpoint"][2]) - 20.5) < 0.5 and e["lengthMM"] > 20)
            + edges_where(body, lambda e: abs(e["midpoint"][1] - 21) < 0.5 and abs(e["midpoint"][2] - 20.5) < 0.5 and abs(e["lengthMM"] - 29) < 0.5))
    return body


@problem("4.17", 255293, features=("Extrude Boss", "Sketch: Slot", "Extrude Cut", "Fillet and Chamfer"))
def p4_17():
    # Base 95 × 82 × 24 with a 26 × 8 groove along x under the slot line
    # (v = 21 from the near edge); a 71 × 35 × 47 tower along the far edge
    # with a 20 × 45° chamfer on its top-right edge and a 13 × 17 slot along
    # x through it; a stadium boss 4 tall (R11.5, centres (25, 21) and
    # (70, 21)) with a 13-wide through slot (5 wall) down through the base.
    body = extrude(Sketch(top(0)).rect(0, 0, 95, 82), (47, 41), 24)
    extrude(Sketch(front(-82)).poly([(0, 24), (71, 24), (71, 51), (51, 71), (0, 71)]), (30, 40), 35, union=[body])
    extrude(Sketch(bottom(72)).rect(-1, -71, 72, -58), (30, -64.5), 18, cut=[body])
    extrude(Sketch(top(24)).slot((25, 21), (70, 21), 11.5), (47.5, 21), 4, union=[body])
    extrude(Sketch(bottom(29)).slot((25, -21), (70, -21), 6.5), (47.5, -21), 30, cut=[body])
    extrude(Sketch(right(-1)).rect(8, -1, 34, 8), (21, 3), 97, cut=[body])
    return body


@problem("4.18", 337082, features=("Extrude Boss", "Extrude Cut", "Sketch: Arcs", "Sketch: Fillets"))
def p4_18():
    # Hanger: 20-thick plate 145 wide from y = 0 down to R19 rounds about
    # Ø15 holes at (±53.5, −45) and (0, −75), tangent lines between them;
    # a 145 × 12 bar on top, 42 deep, set 7 back from the plate's front;
    # two 22-wide ears (R21 about Ø21 holes at y = 33, mid-depth) at its ends.
    c1 = (53.5, -45.0); c0 = (0.0, -75.0); R = 19.0
    d = (c0[0] - c1[0], c0[1] - c1[1]); L = math.hypot(*d)
    n = (-d[1] / L, d[0] / L)
    ang = math.degrees(math.atan2(n[1], n[0]))              # ≈ −60.7°
    T1 = (c1[0] + R * n[0], c1[1] + R * n[1]); T0 = (c0[0] + R * n[0], c0[1] + R * n[1])
    sk = (Sketch(front(0)).line((-72.5, 0), (72.5, 0)).line((72.5, 0), (72.5, -45))
          .arc(c1, R, ang, 0).line(T1, T0).arc(c0, R, -90, ang)
          .arc(c0, R, -180 - ang, -90).line((-T0[0], T0[1]), (-T1[0], T1[1]))
          .arc((-53.5, -45), R, 180, 180 - ang).line((-72.5, -45), (-72.5, 0))
          .circle(c1, 7.5).circle((-53.5, -45), 7.5).circle(c0, 7.5))
    body = extrude(sk, (0, -20), 20)
    extrude(Sketch(front(7)).rect(-72.5, 0, 72.5, 12), (0, 6), 42, union=[body])
    for x0 in (50.5, -72.5):
        ear = (Sketch(right(x0)).line((-49, 12), (-7, 12)).line((-7, 12), (-7, 33)).arc((-28, 33), 21, 0, 180)
               .line((-49, 33), (-49, 12)).circle((-28, 33), 10.5))
        extrude(ear, (-28, 20), 22, union=[body])
    return body


@problem("4.19", 73407, features=("Extrude Boss", "Extrude Cut", "Sketch: Slot", "Sketch: Arcs", "Fillet"))
def p4_19():
    # Saddle: 9-thick strip 115 long (x −58..57), 50 wide, with an R23/R32
    # arch about the origin and a 9 × 42 upright at the right end; 3 × R2
    # in the concave corners, 4 × R7 on the strip's left corners and the
    # upright's top corners, 2 × Ø8 at (−51, ±18), a 12-wide round-ended
    # slot 18 deep (to its centre) through the upright.
    xo = math.sqrt(32 ** 2 - 81)                       # outer arc meets y = 9
    ao = math.degrees(math.atan2(9, xo))
    sk = (Sketch(front(-25)).poly([(-58, 0), (-58, 9), (-xo, 9)], close=False)
          .arc((0, 0), 32, ao, 180 - ao)
          .poly([(xo, 9), (48, 9), (48, 42), (57, 42), (57, 0), (23, 0)], close=False)
          .arc((0, 0), 23, 0, 180).line((-23, 0), (-58, 0)))
    body = extrude(sk, (-45, 4.5), 50)
    fillet(body, 2.0, edges_near(body, (48, 9, 0), 0.6) + edges_near(body, (xo, 9, 0), 0.6) + edges_near(body, (-xo, 9, 0), 0.6))
    fillet(body, 7.0, edges_near(body, (-58, 4.5, 25), 0.6) + edges_near(body, (-58, 4.5, -25), 0.6)
           + edges_near(body, (52.5, 42, 25), 0.6) + edges_near(body, (52.5, 42, -25), 0.6))
    for z in (18, -18):
        extrude(Sketch(bottom(10)).circle((-51, z), 4), (-51, z), 11, cut=[body])
    extrude(Sketch(left(58)).slot((0, 24), (0, 50), 6), (0, 30), 10, cut=[body])
    return body


@problem("4.20", 436580, features=("Extrude Boss", "Extrude Cut", "Sketch: Slot", "Fillet"))
def p4_20():
    # Split clamp on a stand: base 125 × 75 × 22 (top at y = 0) with two
    # 11 × 17 slots along z at x = ±42.5; a 28 × 48 stem up to a Ø83/Ø55
    # cylinder 55 long along x centred at y = 80; a Ø32 ear 58 long along z
    # centred 45 above the cylinder axis with a Ø13 hole and a 5 slit down
    # into the bore. R5 fillets on the base's edges and the stem's foot
    # (the sheet says R5 everywhere; the rest is left sharp).
    body = extrude(Sketch(top(-22)).rect(-62.5, -37.5, 62.5, 37.5), (0, 0), 22)
    extrude(Sketch(top(0)).rect(-14, -24, 14, 24), (0, 0), 50, union=[body])
    extrude(Sketch(right(-27.5)).circle((0, 80), 41.5).circle((0, 80), 27.5), (0, 115), 55, union=[body])
    ear = Sketch(front(-29)).line((-16, 100), (16, 100)).line((16, 100), (16, 125)).arc((0, 125), 16, 0, 180).line((-16, 125), (-16, 100))
    extrude(ear, (0, 120), 58, union=[body])
    extrude(Sketch(right(-28)).circle((0, 80), 27.5), (0, 80), 56, cut=[body])
    extrude(Sketch(front(-30)).circle((0, 125), 6.5), (0, 125), 60, cut=[body])
    extrude(Sketch(bottom(150)).rect(-28, -2.5, 28, 2.5), (0, 0), 80, cut=[body])
    for x in (42.5, -42.5):
        extrude(Sketch(bottom(1)).slot((x, -8.5), (x, 8.5), 5.5), (x, 0), 24, cut=[body])
    fillet(body, 5.0, edges_where(body, lambda e: abs(e["midpoint"][1] + 11) < 0.5 and abs(abs(e["midpoint"][0]) - 62.5) < 0.5))
    fillet(body, 5.0, edges_where(body, lambda e: abs(e["midpoint"][1]) < 0.01 and (abs(e["midpoint"][0]) > 60 or abs(e["midpoint"][2]) > 36)))
    fillet(body, 5.0, edges_where(body, lambda e: abs(e["midpoint"][1]) < 0.01 and (abs(abs(e["midpoint"][0]) - 14) < 0.5 or abs(abs(e["midpoint"][2]) - 24) < 0.5)))
    return body


@problem("4.22", 106977, features=("Extrude Boss", "Extrude Cut", "Sketch: Arcs"))
def p4_22():
    # Ø42/Ø25 tube 45 long along z about the origin; a 52 × 37 × 35 block
    # under its right half (top at y = 0) carrying a 35-wide, 15-thick arm
    # to an R17.5 end about the Ø12 hole at x = 77; Ø12 at x = 41 through
    # the block, Ø22 × 2 rings round both holes, a 12 × 8 slot along the
    # block's bottom (the hole tangent to its faces). R2 rounds left out.
    body = extrude(Sketch(front(-22.5)).circle((0, 0), 21).circle((0, 0), 12.5), (16, 0), 45)
    extrude(Sketch(front(-17.5)).rect(0, -37, 52, 0), (30, -20), 35, union=[body])
    arm = Sketch(top(-15)).line((52, -17.5), (52, 17.5)).line((52, 17.5), (77, 17.5)).arc((77, 0), 17.5, -90, 90).line((77, -17.5), (52, -17.5))
    extrude(arm, (70, 0), 15, union=[body])
    extrude(Sketch(front(-23)).circle((0, 0), 12.5), (0, 0), 46, cut=[body])
    for x, depth in ((41, 41), (77, 20)):
        extrude(Sketch(top(0)).circle((x, 0), 11).circle((x, 0), 6), (x + 8.5, 0), 2, union=[body])
        extrude(Sketch(bottom(3)).circle((x, 0), 6), (x, 0), depth, cut=[body])
    extrude(Sketch(right(-1)).rect(-6, -38, 6, -29), (0, -33), 54, cut=[body])
    return body


@problem("4.24", 87204, features=("Extrude Boss", "Extrude Cut", "Sketch: Arcs", "Fillet"))
def p4_24():
    # 108 × 54 × 11 base (R10 on the near corners, 4 × Ø8 at 10 in from the
    # ends, 10 and 35 from the far edge); a 52-wide block whose section is
    # an R49 arc from the near edge up to 21 at z = 40.2, then a 12-high
    # step to 48 (6 of base left bare); a V-groove along z: 18-wide floor 6
    # up, sides tangent to the R15 circle centred on the block's top plane.
    zc = math.sqrt(49 ** 2 - 28 ** 2)                       # 40.21 from the near edge
    body = extrude(Sketch(top(0)).rect(-54, -27, 54, 27), (0, 0), 11)
    fillet(body, 10.0, edges_where(body, lambda e: abs(e["midpoint"][1] - 5.5) < 0.5 and abs(e["midpoint"][2] - 27) < 0.5 and abs(abs(e["midpoint"][0]) - 54) < 0.5))
    for x in (-44, 44):
        for z in (-17, 8):
            extrude(Sketch(bottom(12)).circle((x, z), 4), (x, z), 13, cut=[body])
    u_pk = -27 + zc; a0 = math.degrees(math.atan2(28, -zc))   # start angle of the arc (near edge)
    prof = (Sketch(right(-26)).arc((u_pk, -17), 49, 90, a0)
            .line((u_pk, 32), (u_pk, 23)).line((u_pk, 23), (21, 23)).line((21, 23), (21, 11)).line((21, 11), (-27, 11)))
    extrude(prof, (0, 15), 52, union=[body])
    d = math.hypot(9, 15); L = math.sqrt(d * d - 225)
    ang = math.atan2(15, -9) - math.asin(15 / d)           # tangent from (9, 17) to the R15 circle at (0, 32)
    k = math.cos(ang) / math.sin(ang)
    hw = 9 + 23 * k
    extrude(Sketch(back(30)).poly([(-9, 17), (9, 17), (hw, 40), (-hw, 40)]), (0, 20), 60, cut=[body])
    return body


@problem("4.29", 792960)
def p4_29():
    # Wedge 200 × 100: 90 tall at the left, a 20° slope down to 25 at the
    # right end; between the left plate (up to where the slope meets the
    # top) and the ramp block 55 further on only a 20-deep back band
    # remains; a 50 × 45 slot through the ramp's end.
    t = 200 - 65 / math.tan(math.radians(20))
    body = extrude(Sketch(front(0)).poly([(0, 0), (200, 0), (200, 25), (t, 90), (0, 90)]), (100, 10), 100)
    extrude(Sketch(top(-1)).rect(t, -101, t + 55, -20), (t + 27, -60), 92, cut=[body])
    extrude(Sketch(top(-1)).rect(155, -75, 201, -25), (178, -50), 92, cut=[body])
    return body


@problem("4.31", 106460, features=("Extrude Boss", "Extrude Cut", "Sketch: Arcs"))
def p4_31():
    # Open-end wrench: 40 × 5 handle from an R20 eye (Ø12) about the
    # origin, R30 neck fillets tangent to the handle and to the R38 head
    # disc centred 315 away; the disc alone is 15 thick (the side view
    # shows the thick part starting at the disc's edge). Jaw 35 wide with
    # an R25 bottom whose apex is 34 from the disc's far edge (x = 311).
    x30 = -math.sqrt(68 ** 2 - 50 ** 2); xt = 38 * x30 / 68; yt = 38 * 50 / 68
    X30 = 315 + x30
    aT = math.degrees(math.atan2(yt, xt))                     # ≈ 132.7°
    aU = math.degrees(math.atan2(yt - 50, xt - x30))          # upper fillet end angle ≈ −47.4°
    thin = (Sketch(front(-2.5)).line((0, 20), (X30, 20)).arc((X30, 50), 30, -90, aU)
            .arc((315, 0), 38, 360 - aT, 360 + aT).arc((X30, -50), 30, -aU, 90)
            .line((X30, -20), (0, -20)).arc((0, 0), 20, 90, 270).circle((0, 0), 6))
    body = extrude(thin, (150, 0), 5)
    extrude(Sketch(front(-7.5)).circle((315, 0), 38), (300, 0), 15, union=[body])
    cx = 311 + 25; xb = cx - math.sqrt(625 - 17.5 ** 2)
    aJ = math.degrees(math.atan2(17.5, xb - cx))              # ≈ 135.6°
    jaw = (Sketch(front(-8)).line((xb, 17.5), (360, 17.5)).line((360, 17.5), (360, -17.5)).line((360, -17.5), (xb, -17.5))
           .arc((cx, 0), 25, aJ, 360 - aJ))
    extrude(jaw, (330, 0), 16, cut=[body])
    return body


@problem("4.32", 104271, features=("Extrude Boss", "Extrude Cut", "Sketch: Slot", "Fillet"))
def p4_32():
    # 100 × 42 × 10 base with a 60-long block at the right end: vertical
    # face 31 tall, a 25-long face rising at 58° to a ridge, then a 32°
    # face down to the right end; R3 on the four outline corners. Stadium
    # boss R7 × 4 (centres 19 apart along z at x = −83) with an R5 through
    # slot. A 23-wide groove 7 deep with 55° sides runs down the 32° face.
    a = math.radians(58); t32 = math.tan(math.radians(32))
    px = -60 + 25 * math.cos(a); py = 31 + 25 * math.sin(a)
    yend = py - (0 - px) * t32
    prof = Sketch(front(-21)).poly([(-100, 0), (0, 0), (0, yend), (px, py), (-60, 31), (-60, 10), (-100, 10)])
    body = extrude(prof, (-30, 15), 42)
    fillet(body, 3.0, edges_where(body, lambda e: abs(abs(e["midpoint"][2]) - 21) < 0.5 and e["lengthMM"] > 5
                                  and (abs(e["midpoint"][0]) < 0.5 or abs(e["midpoint"][0] + 100) < 0.5)))
    extrude(Sketch(top(10)).slot((-83, -9.5), (-83, 9.5), 7), (-83, 0), 4, union=[body])
    extrude(Sketch(bottom(15)).slot((-83, -9.5), (-83, 9.5), 5), (-83, 0), 16, cut=[body])
    s32, c32 = math.sin(math.radians(32)), math.cos(math.radians(32))
    O = (5.0, py - (5 - px) * t32, 0.0)
    hb = 11.5 - 7 / math.tan(math.radians(55))
    groove = Sketch(plane_at(O, (0, 0, 1), (s32, c32, 0))).poly([(-11.5, 0), (-11.5, 5), (11.5, 5), (11.5, 0), (hb, -7), (-hb, -7)])
    extrude(groove, (0, -3), 75, cut=[body])
    return body


@problem("4.42", 359860, features=("Extrude Boss", "Extrude Cut"))
def p4_42():
    # V-block 135 long: 60 × 52 block with a 30° half-angle V (42 wide at
    # the top) on an 18 × 23 stem whose underside carries four right-angle
    # sawteeth of 28 pitch.
    d = 21 / math.tan(math.radians(30))
    prof = Sketch(front(0)).poly([(-30, 0), (-30, 52), (-21, 52), (0, 52 - d), (21, 52), (30, 52), (30, 0),
                                   (9, 0), (9, -23), (-9, -23), (-9, 0)])
    body = extrude(prof, (-20, 20), 135)
    for i in range(4):
        u0 = -28 * i
        tooth = Sketch(right(-10)).poly([(u0 + 1, -24), (u0 - 29, -24), (u0 - 14, -9)])
        extrude(tooth, (u0 - 14, -20), 20, cut=[body])
    return body


@problem("4.37", 14449, features=("Extrude Boss", "Extrude Cut", "Fillet and Chamfer"))
def p4_37():
    # Ø50 × 13 disc, Ø7 centre hole, four radial slots of width 12 / 11 /
    # 10 / 13 (top, right, bottom, left) whose round inner ends are centred
    # on an R12 circle; 2 × 45° chamfer on one face's rim.
    body = extrude(Sketch(front(0)).circle((0, 0), 25).circle((0, 0), 3.5), (15, 0), 13)
    for ang, w in ((90, 12), (0, 11), (270, 10), (180, 13)):
        a = math.radians(ang); c = (12 * math.cos(a), 12 * math.sin(a)); o = (40 * math.cos(a), 40 * math.sin(a))
        extrude(Sketch(front(-1)).slot(c, o, w / 2), (20 * math.cos(a), 20 * math.sin(a)), 15, cut=[body])
    chamfer(body, 2.0, edges_where(body, lambda e: abs(e["midpoint"][2]) < 0.01
                                   and abs(math.hypot(e["midpoint"][0], e["midpoint"][1]) - 25) < 0.6))
    return body


@problem("4.43", 152537, features=("Extrude Boss", "Extrude Cut", "Sketch: Arcs"))
def p4_43():
    # 124 × 164 × 5 back plate (3 × Ø12 at 15 from the edges) with a
    # U-channel (R35 outer, 5 wall, legs 75 long) standing 55 proud of it;
    # the legs are cut back by a plane from full depth 14 above the arc
    # centre to nothing at their tops.
    plate = Sketch(front(-5)).rect(-62, -62, 62, 102).circle((0, 87), 6).circle((47, -47), 6).circle((-47, -47), 6)
    body = extrude(plate, (-55, 80), 5)
    u = (Sketch(front(0)).line((-35, 75), (-35, 0)).arc((0, 0), 35, 180, 360).line((35, 0), (35, 75))
         .line((35, 75), (30, 75)).line((30, 75), (30, 0)).arc((0, 0), 30, 180, 360).line((-30, 0), (-30, 75))
         .line((-30, 75), (-35, 75)))
    extrude(u, (-32.5, 30), 55, union=[body])
    extrude(Sketch(right(-40)).poly([(-55, 14), (-56, 14), (-56, 110), (0, 110), (0, 75)]), (-30, 90), 80, cut=[body])
    return body


@problem("4.52", 219660, features=("Extrude Boss", "Extrude Cut", "Sketch: Slot (arc)", "Fillet"))
def p4_52():
    # L-bracket: 150 × 80 × 15 base whose far end is an R75 arc about the
    # Ø12 hole at x = 75 (Ø25 × 5 counterbore), an R50 centre-point arc
    # slot 16 wide spanning ±30° about that hole; a 15-thick upright 75
    # tall overall with R20 top corners and two Ø15 holes.
    xa = 75 + math.sqrt(75 ** 2 - 40 ** 2); aa = math.degrees(math.atan2(40, xa - 75))
    base = Sketch(top(0)).poly([(0, -40), (0, 40), (xa, 40)], close=False).arc((75, 0), 75, -aa, aa).line((xa, -40), (0, -40))
    body = extrude(base, (40, 0), 15)
    up = Sketch(right(0)).rounded_poly([(-40, 15), (40, 15), (40, 75), (-40, 75)], [0, 0, 20, 20])
    extrude(up, (0, 40), 15, union=[body])
    for z in (-20, 20):
        extrude(Sketch(right(-1)).circle((z, 55), 7.5), (z, 55), 17, cut=[body])
    extrude(Sketch(bottom(16)).circle((75, 0), 6), (75, 0), 17, cut=[body])
    extrude(Sketch(bottom(15)).circle((75, 0), 12.5), (75, 0), 5, cut=[body])
    c1 = (75 + 50 * math.cos(math.radians(30)), 25.0); c2 = (c1[0], -25.0)
    slot = (Sketch(bottom(16)).arc((75, 0), 58, -30, 30).arc(c1, 8, 30, 210).arc((75, 0), 42, -30, 30)
            .arc(c2, 8, 150, 330))
    extrude(slot, (125, 0), 17, cut=[body])
    return body


@problem("4.53", 195556, features=("Extrude Boss", "Extrude Cut", "Fillet"))
def p4_53():
    # Angle bracket: 15-thick bar 175 long; the left 65 (80 at the bottom,
    # a 45° face) is 90 wide with a 16 × 25 leg hanging from its left end
    # (R10 bottom corners, 2 × Ø10 through), the rest a 30-wide arm ending
    # in a 30-square eye 16 tall with an R15 top and Ø15 hole; 2 × Ø8
    # through the wide part at x = 30 and 55.
    body = extrude(Sketch(front(-45)).poly([(0, 0), (65, 0), (80, -15), (16, -15), (16, -40), (0, -40)]), (30, -8), 90)
    extrude(Sketch(front(-15)).rect(60, -15, 175, 0), (120, -8), 30, union=[body])
    eye = (Sketch(front(-15)).line((145, 0), (145, 16)).arc((160, 16), 15, 0, 180).line((175, 16), (175, 0))
           .line((175, 0), (145, 0)).circle((160, 16), 7.5))
    extrude(eye, (160, 5), 30, union=[body])
    for x in (30, 55):
        extrude(Sketch(bottom(1)).circle((x, 0), 4), (x, 0), 17, cut=[body])
    fillet(body, 10.0, edges_where(body, lambda e: abs(e["midpoint"][1] + 40) < 0.5 and abs(abs(e["midpoint"][2]) - 45) < 0.5))
    for z in (-35, 35):
        extrude(Sketch(right(-1)).circle((-z, -27.5), 5), (-z, -27.5), 18, cut=[body])
    return body


@problem("4.54", 120198, features=("Extrude Boss", "Extrude Cut", "Sketch: Slot"))
def p4_54():
    # Fork wedge: 112 × 62 × 15 plate whose far half tapers 8 in per side
    # over the last 50 and carries an 18-wide slot with a Ø18 end 29 from
    # the tip; a 27-long house-section block (62 wide, 15 sides above the
    # plate, 28° roof rising 12) at the near end with 7 × 11 notches cut
    # out of its two outer corners and a Ø7 hole along x 9 below the ridge.
    run = 12 / math.tan(math.radians(28)); hw = 31 - run
    house = Sketch(right(0)).poly([(-62, 0), (0, 0), (0, 30), (-31 + hw, 42), (-31 - hw, 42), (-62, 30)])
    body = extrude(house, (-31, 10), 27)
    plate = (Sketch(top(0)).poly([(0, 0), (0, -62), (62, -62), (112, -54), (112, -40), (83, -40)], close=False)
             .arc((83, -31), 9, 90, 270).line((83, -22), (112, -22)).line((112, -22), (112, -8)).line((112, -8), (62, 0))
             .line((62, 0), (0, 0)))
    extrude(plate, (40, -31), 15, union=[body])
    for v0, v1 in ((-11, 1), (-63, -51)):
        extrude(Sketch(top(-1)).rect(-1, v0, 7, v1), (3, (v0 + v1) / 2), 45, cut=[body])
    extrude(Sketch(right(-1)).circle((-31, 33), 3.5), (-31, 33), 29, cut=[body])
    return body


@problem("4.35", 3179, features=("Extrude Boss", "Extrude Cut", "Fillet"))
def p4_35():
    # C-clip, 5 thick throughout, 10 deep: 25-long flanges with a 2-deep,
    # 8-long groove inside leaving a 3 lip at each tip, a 28-tall web with
    # a 45° corner up to the top flange (top at 37); R2 in the square
    # inner corner; Ø3 through each flange (x = 18) and Ø5 through the
    # web 12 up.
    c = -28 + 5 * math.sqrt(2)
    prof = Sketch(front(0)).poly([(0, 0), (25, 0), (25, 5), (22, 5), (22, 3), (14, 3), (14, 5), (5, 5), (5, 5 - c),
                                   (32 + c, 32), (14, 32), (14, 34), (22, 34), (22, 32), (25, 32), (25, 37), (9, 37), (0, 28)])
    body = extrude(prof, (2.5, 15), 10)
    fillet(body, 2.0, edges_near(body, (5, 5, 5), 0.6))
    for y0, d in ((-1, 7), (31, 7)):
        extrude(Sketch(bottom(y0 + d)).circle((18, 5), 1.5), (18, 5), d + 1, cut=[body])
    extrude(Sketch(right(-1)).circle((-5, 12), 2.5), (-5, 12), 7, cut=[body])
    return body


@problem("4.48", 886973, features=("Extrude Boss", "Extrude Cut", "Fillet"))
def p4_48():
    # Omega clamp 100 deep: Ø129/Ø95 ring about the origin; two parallel
    # 17-thick legs leaning at 60°, each tangent to both circles (the right
    # leg's inner edge through the origin); a 17-thick base whose underside
    # is 90 below the origin, spanning x = −110..115, open between the
    # legs; R20 / R12
    # in the foot corners; 2 × Ø20 at x = ±90.
    n = (math.cos(math.radians(30)), math.sin(math.radians(30)))
    def on_line(s, y):                      # x where n·p = s at height y
        return (s - n[1] * y) / n[0]
    def circ_pts(s, R):                     # lower intersection of n·p = s with r = R
        h = math.sqrt(max(0.0, R * R - s * s)); px, py = s * n[0], s * n[1]
        return (px + h * 0.5, py - h * math.sqrt(3) / 2)
    xl = -110.0
    body = extrude(Sketch(front(-50)).rect(xl, -90, 115, -73), (0, -80), 100)
    extrude(Sketch(front(-50)).circle((0, 0), 64.5).circle((0, 0), 47.5), (56, 0), 100, union=[body])
    T = circ_pts(-64.5, 64.5); P = circ_pts(-47.5, 64.5)
    aT = math.degrees(math.atan2(T[1], T[0])); aP = math.degrees(math.atan2(P[1], P[0]))
    left = (Sketch(front(-50)).line((on_line(-64.5, -90), -90), T).arc((0, 0), 64.5, aT, aP)
            .line(P, (on_line(-47.5, -90), -90)).line((on_line(-47.5, -90), -90), (on_line(-64.5, -90), -90)))
    extrude(left, (on_line(-56, -80), -80), 100, union=[body])
    D = circ_pts(17, 64.5); E = circ_pts(0, 64.5)
    aD = math.degrees(math.atan2(D[1], D[0])); aE = math.degrees(math.atan2(E[1], E[0]))
    rightleg = (Sketch(front(-50)).line((on_line(0, -90), -90), (on_line(17, -90), -90)).line((on_line(17, -90), -90), D)
                .arc((0, 0), 64.5, aE, aD).line(E, (on_line(0, -90), -90)))
    extrude(rightleg, (on_line(8.5, -80), -80), 100, union=[body])
    extrude(Sketch(front(-51)).circle((0, 0), 47.5), (0, 0), 102, cut=[body])
    gap = Sketch(front(-51)).poly([(on_line(-47.5, -91), -91), (on_line(0, -91), -91), (on_line(0, -20), -20), (on_line(-47.5, -20), -20)])
    extrude(gap, (on_line(-23, -80), -80), 102, cut=[body])
    fillet(body, 20.0, edges_near(body, (on_line(-64.5, -73), -73, 0), 0.6))
    fillet(body, 12.0, edges_near(body, (on_line(17, -73), -73, 0), 0.6))
    for x in (-90, 90):
        extrude(Sketch(bottom(-72)).circle((x, 0), 10), (x, 0), 19, cut=[body])
    return body


@problem("4.59", 144672, features=("Extrude Boss", "Extrude Cut", "Sketch: Arcs"))
def p4_59():
    # 150 × 50 × 15 plate with an R25 end about the Ø25 hole at the origin
    # and a Ø15 at x = 135; a 15-thick R15 lug (Ø12) standing 30 up at
    # x = 35 on the near 15 of the width, and a matching lug hanging 30
    # down beside the near edge at x = 135.
    plate = Sketch(top(0)).line((0, 25), (150, 25)).line((150, 25), (150, -25)).line((150, -25), (0, -25)).arc((0, 0), 25, 90, 270)
    plate.circle((0, 0), 12.5).circle((135, 0), 7.5)
    body = extrude(plate, (75, 10), 15)
    up = Sketch(front(-25)).line((20, 15), (20, 30)).arc((35, 30), 15, 0, 180).line((50, 30), (50, 15)).line((50, 15), (20, 15)).circle((35, 30), 6)
    extrude(up, (35, 20), 15, union=[body])
    down = Sketch(front(-40)).line((120, 15), (150, 15)).line((150, 15), (150, -15)).arc((135, -15), 15, 180, 360).line((120, -15), (120, 15)).circle((135, -15), 6)
    extrude(down, (135, 0), 15, union=[body])
    return body


@problem("4.56", 190758, features=("Extrude Boss", "Extrude Cut", "Sketch: Slot"))
def p4_56():
    # 150 × 55 × 32 bar with R32 quarter-round ends on top, a 37 × 20
    # channel along its top, a 125 × 55 × 10 pad under it, and two 12-wide
    # slots (33 between centres, 28 apart) through the channel floor.
    prof = (Sketch(front(-27.5)).line((0, 0), (150, 0)).line((150, 0), (150, 0.0001)) if False else
            Sketch(front(-27.5)).line((0, 0), (150, 0)).arc((118, 0), 32, 0, 90).line((118, 32), (32, 32)).arc((32, 0), 32, 90, 180))
    body = extrude(prof, (75, 15), 55)
    extrude(Sketch(front(-27.5)).rect(12.5, -10, 137.5, 0), (75, -5), 55, union=[body])
    extrude(Sketch(bottom(40)).rect(-1, -18.5, 151, 18.5), (75, 0), 28, cut=[body])
    for a, b in ((28, 61), (89, 122)):
        extrude(Sketch(bottom(13)).slot((a, 0), (b, 0), 6), ((a + b) / 2, 0), 24, cut=[body])
    return body


@problem("4.57", 347206, features=("Extrude Boss", "Extrude Cut", "Fillet"))
def p4_57():
    # Ø65/Ø32 tube 100 long along x; a 45 × 65 lug block from the axis
    # level down to an R22.5 eye centred 52 below (Ø25 hole, 10 × 5 keyway
    # above it); R6 where the lug's flanks meet the tube (see below).
    body = extrude(Sketch(right(-50)).circle((0, 0), 32.5).circle((0, 0), 16), (0, 24), 100)
    lug = (Sketch(front(-32.5)).line((-22.5, 0), (22.5, 0)).line((22.5, 0), (22.5, -52)).arc((0, -52), 22.5, 180, 360)
           .line((-22.5, -52), (-22.5, 0)).circle((0, -52), 12.5))
    extrude(lug, (0, -20), 65, union=[body])
    extrude(Sketch(right(-51)).circle((0, 0), 16), (0, 0), 102, cut=[body])
    extrude(Sketch(front(-33)).rect(-5, -40, 5, -34), (0, -37), 66, cut=[body])
    # The R6 blends along the flank/tube arcs end where the lug's z-faces
    # are tangent to the tube; OCCT rejects them ("blended solid failed
    # validity checking"), so they are left off (about -0.4 %).
    return body


# ---------------------------------------------------------------------------
# Round 4 (2026-09-04): the sheets earlier passes deferred, built on the most
# defensible reading; each recipe's comment states the assumptions taken.


@problem("4.11", 89495, features=("Extrude Boss", "Extrude Cut", "Sketch: Arcs"))
def p4_11():
    # Keyed plate 110 × 52, 17 thick (R20 on the right corners) with an
    # 8-tall raised band on the left: a lip left of the R96 arc and a block
    # between the R72 arc and x = 59, both arcs about (102, 0) (8 from the
    # right end); Ø28 through at x = 65 (45 from the end) with an 8-wide
    # through keyway to 19 from its centre; a 22-wide slot 7 deep from the
    # hole to the end; 2 × Ø9 through the groove floor on the R85 arc at
    # ±17.5° from the Ø28 centre (the sheet's 35°). Hand: 89,494.9.
    a96 = math.degrees(math.asin(26 / 96)); x96 = 102 - math.sqrt(96 ** 2 - 26 ** 2)
    a72 = math.degrees(math.asin(26 / 72)); x72 = 102 - math.sqrt(72 ** 2 - 26 ** 2)
    body = extrude(Sketch(top(0)).rounded_poly([(0, -26), (110, -26), (110, 26), (0, 26)], [0, 20, 20, 0]), (50, 0), 17)
    lip = (Sketch(top(17)).line((0, -26), (0, 26)).line((0, 26), (x96, 26)).arc((102, 0), 96, 180 - a96, 180 + a96)
           .line((x96, -26), (0, -26)))
    extrude(lip, (3, 0), 8, union=[body])
    blk = (Sketch(top(17)).line((x72, 26), (59, 26)).line((59, 26), (59, -26)).line((59, -26), (x72, -26))
           .arc((102, 0), 72, 180 - a72, 180 + a72))
    extrude(blk, (45, 0), 8, union=[body])
    extrude(Sketch(top(-1)).circle((65, 0), 14), (65, 0), 27, cut=[body])
    extrude(Sketch(top(-1)).rect(65, -4, 84, 4), (80, 0), 27, cut=[body])
    extrude(Sketch(top(10)).rect(65, -11, 111, 11), (95, 0), 8, cut=[body])
    c, s = math.cos(math.radians(17.5)), math.sin(math.radians(17.5))
    t = (-74 * c + math.sqrt((74 * c) ** 2 + 4 * 5856)) / 2          # ray from (65,0) meets R85 about (102,0)
    for sgn in (1, -1):
        extrude(Sketch(top(-1)).circle((65 - t * c, sgn * t * s), 4.5), (65 - t * c, sgn * t * s), 19, cut=[body])
    return body


@problem("4.12", 59730, features=("Extrude Boss", "Extrude Cut", "Sketch: Trim"))
def p4_12():
    # Fan housing: 80-square (R7 corners) 25 long; the middle 20 is a
    # mid-plane cut to Ø85 clipped by the 80 flats (the 'Ø85 CUTAWAY'),
    # leaving two 2.5 plates with 4 × Ø6 concentric with the R7 corners;
    # Ø70 bore 17 deep from the front, Ø50 through the 8 flange behind.
    # Hand: 59,729.8.
    sq = Sketch(front(0)).rounded_poly([(-40, -40), (40, -40), (40, 40), (-40, 40)], 7)
    for sx in (1, -1):
        for sy in (1, -1):
            sq.circle((33 * sx, 33 * sy), 3)
    body = extrude(sq, (0, 38), 25)
    h = math.sqrt(42.5 ** 2 - 40 ** 2); a0 = math.degrees(math.atan2(h, 40))
    cut = Sketch(front(2.5))
    for k in range(4):
        rot = 90 * k
        def P(x, y):
            r = math.radians(rot); return (x * math.cos(r) - y * math.sin(r), x * math.sin(r) + y * math.cos(r))
        cut.arc((0, 0), 42.5, a0 + rot, 90 - a0 + rot)
        cut.line(P(h, 40), P(h, 45)).line(P(h, 45), P(45, 45)).line(P(45, 45), P(45, h)).line(P(45, h), P(40, h))
    for k in range(4):
        r = math.radians(90 * k)
        extrude(cut, (36 * math.cos(r) - 36 * math.sin(r), 36 * math.sin(r) + 36 * math.cos(r)), 20, cut=[body])
    extrude(Sketch(front(-1)).circle((0, 0), 35), (0, 0), 18, cut=[body])
    extrude(Sketch(front(-1)).circle((0, 0), 25), (0, 0), 27, cut=[body])
    return body


def extrude_intersect(sk, seed, distance, targets):
    """Extrude with the inline `intersect` boolean (the kit's extrude() has
    no flag for it): the target keeps its id and becomes the common volume."""
    sk.commit()
    X("feature.extrude", {"sketchID": sk.id, "seedPoint": list(seed), "distance": distance,
                          "boolean": "intersect", "booleanTargets": list(targets)})
    return targets[0]


@problem("4.13", 38349, features=("Extrude Boss", "Extrude Cut", "Sketch: Offset", "Sketch: Trim", "Fillet"))
def p4_13():
    # Y-lever = (front Y profile, through z) ∩ (plan lever profile, through
    # y). Y: 14-tall bar from the hub's edge (x = −25) to x = 35, two 8-thick
    # arms from (35, ±7) to (75, ±32.5) (32.5°), 8-tall tabs to the end; R5
    # in the crotch and the four concave junction corners. Lever: hull of
    # R25 about the origin and R12 about (100, 0), Ø36 bore (the '7' wall),
    # Ø12 end hole, a window offset 7 inside the sides and 7 outside both
    # holes (R25 / R13 arcs) with rounded corners; their radius is not
    # called out — a circle fit on the drawing's corner gives R4 (centre
    # (27.7, 10.6) vs R4's (27.0, 10.6)). Hand (raster, R4): 38,380.6;
    # sharp corners would read −1.19 %.
    phi = math.atan2(25.5, 40); t = math.tan(phi); c = math.cos(phi); s = math.sin(phi)
    x_in0 = 35 + 8 * s - (7 - 8 * c) / t                # inner arm line crosses y = 0 (crotch apex)
    x_pc = x_in0 + 24.5 / t                              # inner line meets the tab's underside
    pts = [(-25, -7), (35, -7), (75, -32.5), (115, -32.5), (115, -24.5), (x_pc, -24.5), (x_in0, 0),
           (x_pc, 24.5), (115, 24.5), (115, 32.5), (75, 32.5), (35, 7), (-25, 7)]
    radii = [0, 5, 0, 0, 0, 5, 5, 5, 0, 0, 0, 5, 0]
    R = 4.0
    alpha = math.asin(13 / 100); n = (math.sin(alpha), math.cos(alpha)); tv = (n[1], -n[0])
    d = 18 - R; h = math.sqrt((25 + R) ** 2 - d * d)
    C1 = (d * n[0] + h * n[1], d * n[1] - h * n[0]); b = math.degrees(math.atan2(C1[1], C1[0]))
    a = 5 - R; bb = -math.sqrt((13 + R) ** 2 - a * a)
    C2 = (100 + a * n[0] + bb * tv[0], a * n[1] + bb * tv[1]); g = math.degrees(math.atan2(C2[1], C2[0] - 100))
    a1 = math.degrees(math.atan2(n[1], n[0]))
    T2 = (C1[0] + R * n[0], C1[1] + R * n[1]); T3 = (C2[0] + R * n[0], C2[1] + R * n[1])
    lever = (Sketch(top(-40)).hull2((0, 0), 25, (100, 0), 12).circle((0, 0), 18).circle((100, 0), 6)
             .arc((0, 0), 25, -b, b)
             .arc(C1, R, a1, 180 + b).line(T2, T3).arc(C2, R, g - 180, a1).arc((100, 0), 13, g, 360 - g)
             .arc((C2[0], -C2[1]), R, 360 - a1, 540 - g).line((T3[0], -T3[1]), (T2[0], -T2[1]))
             .arc((C1[0], -C1[1]), R, 180 - b, 360 - a1))
    body = extrude(lever, (0, 21.5), 80)
    yprof = Sketch(front(-40)).rounded_poly(pts, radii)
    return extrude_intersect(yprof, (0, 0), 80, [body])


@problem("4.36", 6333, features=("Revolve", "Extrude Cut", "Sketch: Fillets", "Fillet and Chamfer"))
def p4_36():
    # Turned pin: Ø19 base, Ø13 shank, 40 tall; the shoulder is an R5/R5
    # S-curve (two tangent sketch fillets). Its position is read from the
    # drawn tangent edges — both views show them at y = 13.4 / 17.0 / 20.5,
    # i.e. the S centred at y = 17 (the printed 16.00 lands on nothing
    # drawn); 1 × 45° chamfer on the top rim; a D-flat 6 deep beyond 4.5
    # from the axis on the top; a Ø12 bore 14 deep with a flat at 4 from
    # the axis; one Ø2 cross hole at y = 7 through one wall into the bore
    # (Section A-A shows one wall only). Hand: 6,332.6.
    th = math.acos(0.7); h = 5 * math.sin(th)                # each fillet turns 45.57°, S is 7.14 tall
    yc = 17.0
    prof = (Sketch(front(0)).poly([(0, 0), (9.5, 0), (9.5, yc - h)], close=False)
            .arc((4.5, yc - h), 5, 0, math.degrees(th))
            .arc((11.5, yc + h), 5, 180, 180 + math.degrees(th))
            .poly([(6.5, yc + h), (6.5, 39), (5.5, 40), (0, 40), (0, 0)], close=False))
    body = revolve(prof, (3, 25), (0, 0), (0, 1))
    extrude(Sketch(front(-10)).rect(4.5, 34, 8, 41), (6, 37), 20, cut=[body])
    a0 = math.degrees(math.acos(4 / 6))
    bore = Sketch(top(-1)).arc((0, 0), 6, a0, 360 - a0).line((4, -math.sqrt(20)), (4, math.sqrt(20)))
    extrude(bore, (0, 0), 15, cut=[body])
    extrude(Sketch(front(5)).circle((0, 7), 1), (0, 7), 6, cut=[body])
    return body


@problem("4.33", 70920, features=("Extrude Boss", "Extrude Cut", "Sketch: Slot", "Sketch: Arcs", "Sketch: Fillets"))
def p4_33():
    # L-bracket, both legs 10 thick. Plate (plan, z = −Y): a 50-wide band
    # from the upright to an R38 boss about the Ø48 hole 50 down (Detail A:
    # R38 / R24), R10 in the two side junctions, R50 concave blends down to
    # an R18 lobe about the Ø15 hole 45 further, a 6-wide slit whose lower
    # edge is the 25° radial from the hole centre. Upright 50 × 10 to 75
    # tall with an R25 top (centre 50 up) and an R7 slot between 25 and 50.
    # Hand (raster): 70,914.7.
    body = extrude(Sketch(top(0)).rect(-25, -50, 25, 10), (0, -20), 10)
    extrude(Sketch(top(0)).circle((0, -50), 38), (0, -50), 10, union=[body])
    extrude(Sketch(top(0)).circle((0, -95), 18), (0, -95), 10, union=[body])
    zj = 50 - math.sqrt(38 ** 2 - 25 ** 2)                      # side lines meet the boss
    yi = (-1120 / 45 - 145) / 2; xi = math.sqrt(324 - (yi + 95) ** 2)        # boss/lobe intersection
    fillet(body, 10.0, edges_near(body, (25, 5, zj), 0.6) + edges_near(body, (-25, 5, zj), 0.6))
    fillet(body, 50.0, edges_near(body, (xi, 5, -yi), 0.6) + edges_near(body, (-xi, 5, -yi), 0.6))
    extrude(Sketch(top(-1)).circle((0, -50), 24), (0, -50), 12, cut=[body])
    extrude(Sketch(top(-1)).circle((0, -95), 7.5), (0, -95), 12, cut=[body])
    a = math.radians(25); dd = (-math.cos(a), -math.sin(a)); n = (-math.sin(a), math.cos(a))
    H = (0, -50)
    P = [H, (H[0] + 45 * dd[0], H[1] + 45 * dd[1]), (H[0] + 45 * dd[0] + 6 * n[0], H[1] + 45 * dd[1] + 6 * n[1]),
         (H[0] + 6 * n[0], H[1] + 6 * n[1])]
    extrude(Sketch(top(-1)).poly(P), (H[0] + 30 * dd[0] + 3 * n[0], H[1] + 30 * dd[1] + 3 * n[1]), 12, cut=[body])
    up = (Sketch(front(-10)).line((-25, 0), (25, 0)).line((25, 0), (25, 50)).arc((0, 50), 25, 0, 180)
          .line((-25, 50), (-25, 0)).slot((0, 25), (0, 50), 7))
    extrude(up, (20, 10), 10, union=[body])
    return body


@problem("4.64", 156401, features=("Extrude Boss", "Extrude Cut"))
def p4_64():
    # Stepped block 86 × 64 (plan V = −z) × 39 with a 30 × 64 × 7 tab under
    # x 31..61. Raised at 39 left of the 40°-from-vertical diagonal through
    # (54, 52) and, beyond V = 52, left of x = 54; the raised top slopes 25°
    # down over V 40..64. Everything right of that is stepped to 21 (the
    # 18), and the corner triangle beyond the parallel line 18 from the
    # corner (86, 0) to 12 (the 9). Ø14 through at (46, 26). Hand: 156,401.1.
    t40 = math.tan(math.radians(40)); t25 = math.tan(math.radians(25))
    x0 = 54 - 52 * t40
    body = extrude(Sketch(top(0)).rect(0, 0, 86, 64), (43, 32), 39)
    extrude(Sketch(top(-7)).rect(31, 0, 61, 64), (46, 32), 7, union=[body])
    extrude(Sketch(top(21)).poly([(x0, 0), (86, 0), (86, 64), (54, 64), (54, 52)]), (70, 30), 19, cut=[body])
    extrude(Sketch(right(-1)).poly([(40, 39), (66, 39 - 26 * t25), (66, 45), (40, 45)]), (55, 42), 88, cut=[body])
    s, c = math.sin(math.radians(40)), math.cos(math.radians(40))
    P1 = (86 - 18 / c - 2 * s, -2 * c); P2 = (86 + 2 * s, 18 / s + 2 * c)
    extrude(Sketch(top(12)).poly([P1, (90, P1[1]), (90, P2[1]), P2]), (82, 5), 10, cut=[body])
    extrude(Sketch(top(-8)).circle((46, 26), 7), (46, 26), 30, cut=[body])
    return body


@problem("4.67", 118352, features=("Extrude Boss", "Extrude Cut", "Sketch: Fillets"))
def p4_67():
    # Chevron plate 100 × 95 × 25: a right-angle V notch from the right
    # (apex (52.5, 47.5)); a 12-wide slot through the middle of the
    # thickness removes everything right of the right-angle triangle whose
    # arms run from the two left corners to an R5-rounded apex at
    # (47.5, 47.5) (Section A-A); Ø12 through at (20, 47.5). Hand: 118,352.3.
    body = extrude(Sketch(front(0)).poly([(0, 0), (100, 0), (52.5, 47.5), (100, 95), (0, 95)]), (20, 20), 25)
    cutter = Sketch(front(6.5)).rounded_poly([(0, 95), (47.5, 47.5), (0, 0), (0, -5), (110, -5), (110, 100), (0, 100)],
                                             [0, 5, 0, 0, 0, 0, 0])
    extrude(cutter, (80, 47.5), 12, cut=[body])
    extrude(Sketch(front(-1)).circle((20, 47.5), 6), (20, 47.5), 27, cut=[body])
    return body


@problem("4.40", 4533315, features=("Extrude Boss", "Extrude Cut", "Fillet"))
def p4_40():
    # Rocker 750 long, 40 thick: ends 100 tall (top at 225), a 40-deep
    # recess between x = ±280 (750/2 − 95) with R30 floor corners, bottom
    # slopes from (±375, 125) tangent to the R70 arc through the origin,
    # R10 on the two end/slope corners. Hub: the R70 arc IS the boss —
    # Ø140 × 85 concentric with the Ø50 bore at (0, 70), R10 rounds on both
    # rims (the drawing's two circles are the rim and its Ø120 tangent
    # edge; their measured ratio 1.17 fits 140/120, not 160/140).
    # Hand: 4,559,179 (+0.57 %); slopes to the origin instead of tangent
    # would read −0.61 %; a Ø160 boss +5.6 %.
    C = (0.0, 70.0); P = (375.0, 125.0)
    d = math.hypot(P[0] - C[0], P[1] - C[1]); L = math.sqrt(d * d - 4900)
    base = math.atan2(C[1] - P[1], C[0] - P[0]); off = math.asin(70 / d)
    T = min(((P[0] + L * math.cos(base + s * off), P[1] + L * math.sin(base + s * off)) for s in (1, -1)), key=lambda t: t[1])
    aT = math.degrees(math.atan2(T[1] - 70, T[0]))
    prof = (Sketch(front(-20)).poly([P, (375, 225), (280, 225), (280, 215)], close=False)
            .arc((250, 215), 30, 270, 360).line((250, 185), (-250, 185)).arc((-250, 215), 30, 180, 270)
            .poly([(-280, 215), (-280, 225), (-375, 225), (-375, 125), (-T[0], T[1])], close=False)
            .arc((0, 70), 70, 180 - aT, 360 + aT).line(T, P))
    body = extrude(prof, (0, 150), 40)
    fillet(body, 10.0, edges_where(body, lambda e: abs(abs(e["midpoint"][0]) - 375) < 0.6 and abs(e["midpoint"][1] - 125) < 0.6))
    extrude(Sketch(front(-42.5)).circle((0, 70), 70), (0, 70), 85, union=[body])
    fillet(body, 10.0, edges_where(body, lambda e: abs(abs(e["midpoint"][2]) - 42.5) < 0.6 and abs(e["lengthMM"] - 2 * math.pi * 70) < 2))
    extrude(Sketch(front(-45)).circle((0, 70), 25), (0, 70), 90, cut=[body])
    return body


@problem("4.1", 7393, features=("Extrude Boss", "Extrude Cut", "Sketch: Polygon", "Fillet and Chamfer"))
def p4_1():
    # Punch along +x: hex shank 6 A/F, 20 long (x −20..0); Ø9 body 120 long
    # with a 1 × 45° chamfer at the shoulder; the last 25 is a flat blade
    # (iso): the round is cut top and bottom by 4° flats ending 1.5 thick,
    # each blended into the Ø9 surface at the 25 line by a concave R5.
    t4 = math.tan(math.radians(4)); n = (math.sin(math.radians(4)), math.cos(math.radians(4)))
    c = n[0] * 120 + n[1] * 0.75                    # line n·p = c through the tip corner (120, 0.75)
    # R5 centre: n·C = c + 5 and |C − (95, 4.5)| = 5
    # parametrise C = (95 + s, 4.5 + w): solve numerically
    # C = P + 5·(cos φ, sin φ) with n·C = c + 5, P = (95, 4.5):  n·P + 5(n·u(φ)) = c + 5
    # → cos(φ − φn) = (c + 5 − n·P) / 5 where φn = atan2(n[1], n[0])
    P = (95.0, 4.5)
    phin = math.atan2(n[1], n[0]); k = (c + 5 - (n[0] * P[0] + n[1] * P[1])) / 5
    phi = phin - math.acos(max(-1.0, min(1.0, k)))                # the solution ahead of the corner (+x)
    C = (P[0] + 5 * math.cos(phi), P[1] + 5 * math.sin(phi)); T = (C[0] - 5 * n[0], C[1] - 5 * n[1])
    body = extrude(Sketch(right(0)).circle((0, 0), 4.5), (0, 0), 120)
    extrude(Sketch(right(-20)).polygon_flats((0, 0), 6, 6), (0, 0), 20, union=[body])
    from kit import chamfer, edges_where
    chamfer(body, 1.0, edges_where(body, lambda e: abs(e["midpoint"][0]) < 0.3 and abs(e["lengthMM"] - 2 * math.pi * 4.5) < 1.0))
    ang = lambda cc, p: math.degrees(math.atan2(p[1] - cc[1], p[0] - cc[0]))
    for sy in (1, -1):
        cut = Sketch(front(-6))
        if sy > 0:
            cut.arc(C, 5, ang(C, (95, 4.5)), ang(C, T))            # short way, CCW
            cut.line(T, (121, 0.75 - t4)).line((121, 0.75 - t4), (121, 10)).line((121, 10), (95, 10)).line((95, 10), (95, 4.5))
            seed = (110, 6)
        else:
            Cm = (C[0], -C[1]); Tm = (T[0], -T[1])
            cut.arc(Cm, 5, ang(Cm, Tm), ang(Cm, (95, -4.5)))          # short way, CCW
            cut.line(Tm, (121, -(0.75 - t4))).line((121, -(0.75 - t4)), (121, -10)).line((121, -10), (95, -10)).line((95, -10), (95, -4.5))
            seed = (110, -6)
        extrude(cut, seed, 12, cut=[body])
    return body


@problem("4.2", 226455, features=("Extrude Boss", "Extrude Cut", "Sketch: Arcs", "Sketch: Fillets", "Fillet and Chamfer"))
def p4_2():
    # Clevis. Front outline: R25 lug about the upper Ø20 hole (0, 100),
    # concave R30 waist arcs centred (±55, 100), 45° edges (90° between)
    # to R10 shoulders, 30° edges (60° between) tangent to an R30 bottom
    # about the lower Ø20 hole at the origin. Body 45 wide (z) with a
    # 25-wide slot 92 deep (R10 top corners); above 92 the lug is 12 thick
    # with R25 blends down to the body (side view); 4 × 5 × 45° chamfers
    # on the outer hole edges. The "20" callout at the bottom matches no
    # feature of this reading (the bottom arc measures R30).
    from kit import chamfer, edges_where
    r2 = math.sqrt(2) / 2
    Tw = (55 - 30 * r2, 100 - 30 * r2)
    L1 = Tw[0] + Tw[1]
    # R10 centre: x + y = L1 − 10√2, 0.866x − 0.5y = 20
    k1 = L1 - 10 * math.sqrt(2)
    x10 = (20 + 0.5 * k1) / (math.cos(math.radians(30)) + 0.5); y10 = k1 - x10
    C10 = (x10, y10)
    T1 = (C10[0] + 10 * r2, C10[1] + 10 * r2)
    T2 = (C10[0] + 10 * math.cos(math.radians(30)), C10[1] - 10 * math.sin(math.radians(30)))
    T3 = (30 * math.cos(math.radians(30)), -15.0)
    sk = Sketch(front(-22.5))
    sk.arc((0, 100), 25, 0, 180)
    for sx in (1, -1):
        M = lambda p: (sx * p[0], p[1])
        if sx > 0:
            sk.arc((55, 100), 30, 180, 225)
            sk.arc(C10, 10, -30, 45)
            sk.arc((0, 0), 30, -150, -30)
        else:
            sk.arc((-55, 100), 30, -45, 0)
            sk.arc((-C10[0], C10[1]), 10, 135, 210)
        sk.line(M(Tw), M(T1)).line(M(T2), M(T3))
    sk.circle((0, 0), 10).circle((0, 100), 10)
    body = extrude(sk, (0, 50), 45)
    # side profile trims above y = 92 outside the 12-thick lug: fillet R25
    # between the lug face (|z| = 6) and the shoulder at y = 92
    for sz in (1, -1):
        u = lambda z: -sz * z                                   # right plane: u = -z
        cutp = Sketch(right(-60))
        ys = 117 - math.sqrt(25 ** 2 - (37 - 22.5) ** 2)
        ang = lambda cc, p: math.degrees(math.atan2(p[1] - cc[1], p[0] - cc[0]))
        pts_arc_start, pts_arc_end = (6.0, 117.0), (22.5, ys)
        # in (u, v) with u = -z: right side z>0 -> u negative
        if sz > 0:
            Fu = (-37.0, 117.0)
            cutp.arc(Fu, 25, ang(Fu, (-22.5, ys)), ang(Fu, (-12, 117)))
            cutp.line((-12, 117), (-12, 200)).line((-12, 200), (-22.5, 200)).line((-22.5, 200), (-22.5, ys))
            seed = (-17, 150)
        else:
            Fu = (37.0, 117.0)
            cutp.arc(Fu, 25, ang(Fu, (12, 117)), ang(Fu, (22.5, ys)))
            cutp.line((12, 117), (12, 200)).line((12, 200), (22.5, 200)).line((22.5, 200), (22.5, ys))
            seed = (17, 150)
        extrude(cutp, seed, 120, cut=[body])
    # slot 25 wide to 92 with R10 top corners (through all x)
    slot = (Sketch(right(-60)).line((-12.5, -40), (12.5, -40)).line((12.5, -40), (12.5, 82))
            .arc((2.5, 82), 10, 0, 90).line((2.5, 92), (-2.5, 92)).arc((-2.5, 82), 10, 90, 180)
            .line((-12.5, 82), (-12.5, -40)))
    extrude(slot, (0, 20), 120, cut=[body])
    # 5 × 45° chamfers on the four outer hole edges, cut as revolved cones
    # (the upper hole meets the R25 blend zone, so its edges are not planar
    # circles and the kernel's edge chamfer is refused there)
    from kit import revolve
    for (yc, zf) in ((0, 22.5), (0, -22.5), (100, 12), (100, -12)):
        sgn = 1 if zf > 0 else -1
        u0 = -zf                                        # right plane: u = -z
        tri = Sketch(right(0)).poly([(u0, yc + 10), (u0, yc + 15.5), (u0 + sgn * 5.5, yc + 10)])
        revolve(tri, (u0 + sgn * 1.5, yc + 11.5), (0, yc), (1, 0), 360, cut=[body])
    return body


@problem("4.3", 10173, features=("Extrude Boss", "Extrude Cut", "Fillet and Chamfer"))
def p4_3():
    # Split shaft collar: ring Ø53 / Ø35 (9 radial wall), 9 thick, 1.5 slit;
    # a Ø4 clamp hole across the slit at mid-wall (4.5 in from the outer
    # surface, i.e. 22 from the centre), counterbored Ø6 for 7 each side
    # of the slit (14); 6 × 1 × 45° chamfers on the outer and bore edges.
    # Closed form 10 185.
    from kit import chamfer, edges_where
    body = extrude(Sketch(top(0)).circle((0, 0), 26.5).circle((0, 0), 17.5), (22, 0), 9)
    extrude(Sketch(top(9)).rect(-0.75, -30, 0.75, -10), (0, -20), -9, cut=[body])   # slit at plan v<0 (z>0 side)
    # clamp hole along x at plan v = -22 (z = 22), y = 4.5
    extrude(Sketch(right(-40)).circle((-22, 4.5), 2), (-22, 4.5), 80, cut=[body])   # u = -z -> u = -22
    extrude(Sketch(right(-7)).circle((-22, 4.5), 3), (-22, 4.5), 14, cut=[body])
    rad = lambda e: math.hypot(e["midpoint"][0], e["midpoint"][2])
    ids = edges_where(body, lambda e: (abs(e["midpoint"][1]) < 0.3 or abs(e["midpoint"][1] - 9) < 0.3)
                      and (abs(rad(e) - 26.5) < 0.6 or abs(rad(e) - 17.5) < 0.6) and e["lengthMM"] > 3)
    chamfer(body, 1.0, ids)
    return body


# ---------------------------------------------------------------- R1B pass ---

def _edges_between(bid, pred_a, pred_b):
    """Edge indices shared by a face matching pred_a and one matching pred_b.
    Written when /v1/edges gave no midpoint/length for some edges, so
    kit.edges_where could not see them (R1B finding). Since #51 (2026-09-16)
    only tangent joins lack them; addressing an edge by its faces still
    works where no crease gives it a midpoint."""
    from kit import faces, G
    fa = {f["index"] for f in faces(bid) if pred_a(f)}
    fb = {f["index"] for f in faces(bid) if pred_b(f)}
    out = []
    for e in G(f"/v1/edges?body={bid}")["edges"]:
        fs = e.get("faces") or []
        if len(fs) == 2 and ((fs[0] in fa and fs[1] in fb) or (fs[1] in fa and fs[0] in fb)):
            out.append(e["index"])
    return out


@problem("4.4", 66264, features=("Extrude Boss", "Extrude Cut", "Fillet and Chamfer"))
def p4_4():
    # Tool block, 78 wide (x) × 48 deep (z) × 32 tall (y). Side profile (z, y):
    # a 19.2-deep foot (48 − 28.80) 10.67 tall whose front face is 8 tall and
    # then slopes back at 60° to the vertical (30° from horizontal) into the
    # z = 6 wall; the body z 6..48 above the 10.67 ledge, the z 6..24 part
    # 32 tall, the z 24..48 part 25 tall (32 − 7) with a 1.5 × 45° chamfer
    # on its outer top edge and Detail A's tongue at the wall: an isosceles
    # trapezoid 1.5 tall, 2 wide on top, 40° flanks (100° included), whose
    # left base corner is the wall. R1.5 TYP on the four foot corners.
    # Front view: both x ends slope in at 24° (from vertical) between
    # y = 13.33 and y = 21.33 (the '8' band), so the top is 70.876 wide.
    # 3 × Ø8 blind holes 10 deep from the top at z = 15, 1.5 × 45° chamfered,
    # centres 12 in from the top face's ends and at x = 39.
    t30 = math.tan(math.radians(30)); t40 = math.tan(math.radians(40)); t24 = math.tan(math.radians(24))
    b = 2 * 1.5 / t40                                       # tongue base extra width (3.575)
    pts = [(0, 0), (19.2, 0), (19.2, 10.6667), (48, 10.6667), (48, 23.5), (46.5, 25),
           (24 + 2 + b, 25), (24 + 2 + b / 2, 26.5), (24 + b / 2, 26.5), (24, 25),
           (24, 32), (6, 32), (6, 8 - 6 * t30), (0, 8)]
    radii = [1.5, 1.5, 1.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1.5, 0]
    body = extrude(Sketch(left(78)).rounded_poly(pts, radii), (30, 20), 78)
    dx = 8 * t24                                            # 3.562 end inset
    for x0, sgn in ((0, 1), (78, -1)):
        end = Sketch(front(-1)).poly([(x0 - sgn, 13.3333), (x0 - sgn, 33), (x0 + sgn * dx, 33),
                                       (x0 + sgn * dx, 21.3333), (x0, 13.3333)])
        extrude(end, (x0 + sgn * 0.5, 30), 50, cut=[body])
    for x in (78 - dx - 12, 39, dx + 12):
        extrude(Sketch(bottom(32)).circle((x, 15), 4), (x, 15), 10, cut=[body])
        rim = edges_where(body, lambda e: abs(e["midpoint"][1] - 32) < 0.3 and abs(e["lengthMM"] - 2 * math.pi * 4) < 1.0
                          and abs(math.hypot(e["midpoint"][0] - x, e["midpoint"][2] - 15) - 4) < 0.3)
        chamfer(body, 1.5, rim)
    return body


@problem("4.5", 107923, features=("Extrude Boss", "Extrude Cut", "Fillet and Chamfer"))
def p4_5():
    # Channelled wedge, 125 long (x) × 43 wide (z, symmetric) × 55 tall.
    # Front profile: R15 lug about the Ø15 hole at (34, 40), a 45° nose
    # tangent to it running down to the x = 0 face (meets it at y = 27.21),
    # a straight top tangent to the lug running down to the x = 125 face at
    # the same height (pixel-measured 27.3; 17.4°), R5 at both of those
    # corners; the lower 18 mm is inset 6 at both ends (Detail A). A 27-wide
    # channel between 8-thick rails, floor 10 above the crest of the R160
    # concave bottom (axis along x, 160 below the crest, so the sides sit
    # 1.45 lower). Ø15 through both rails.
    C = (34.0, 40.0); R = 15.0
    T1 = (C[0] - R / math.sqrt(2), C[1] + R / math.sqrt(2)); h = T1[1] - T1[0]
    lo, hi = 0.15, 1.0
    for _ in range(60):
        t = (lo + hi) / 2
        d = abs(C[1] - h - (125 - C[0]) * t) / math.sqrt(1 + t * t)
        lo, hi = (t, hi) if d < R else (lo, t)
    t = (lo + hi) / 2
    n = (t / math.sqrt(1 + t * t), 1 / math.sqrt(1 + t * t))
    T2 = (C[0] + R * n[0], C[1] + R * n[1])
    a1 = math.degrees(math.atan2(T2[1] - C[1], T2[0] - C[0]))
    # R5 at the two end corners as sketch fillets. Written when the bridge
    # could not fillet these lateral edges (agent_bugs_R1B); on 2026-09-16 a
    # bridge R5 on the sharp corners gave this body's volume exactly, so
    # either route works now.
    th = math.atan(t)
    dL = 5 / math.tan(math.radians(67.5)); dR = 5 / math.tan((math.pi / 2 + th) / 2)
    sk = (Sketch(front(-21.5)).poly([(6, 0), (119, 0), (119, 18), (125, 18), (125, h - dR)], close=False)
          .arc((120, h - dR), 5, 0, 90 - math.degrees(th))
          .line((125 - dR * math.cos(th), h + dR * math.sin(th)), T2)
          .arc(C, R, a1, 135.0)
          .line(T1, (dL / math.sqrt(2), h + dL / math.sqrt(2)))
          .arc((5, h - dL), 5, 135, 180)
          .poly([(0, h - dL), (0, 18), (6, 18), (6, 0)], close=False)
          .circle(C, 7.5))
    body = extrude(sk, (60, 10), 43)
    crest = 160 - math.sqrt(160 ** 2 - 21.5 ** 2)
    extrude(Sketch(bottom(60)).rect(-1, -13.5, 126, 13.5), (60, 0), 60 - (10 + crest), cut=[body])
    extrude(Sketch(right(-1)).circle((0, crest - 160), 160), (0, crest - 160), 127, cut=[body])
    return body


@problem("4.7", 130592, features=("Extrude Boss", "Extrude Cut", "Fillet and Chamfer"))
def p4_7():
    # Clevis plate 125 (x) × 80 (z) × 20: the underside is relieved 6 deep
    # from the fork end to x = 110 with an R6 blending the step (it eats the
    # whole 6 step); a 31-wide slot 62 deep from the fork end with R6 at its
    # closed corners (flat end, 19 straight — pixel-checked, not a full
    # round); an R11 lug about the Ø12 hole at (11, 6), tangent to the x = 0
    # face, over the arms and 10 beyond each side (z 15.5..50), i.e. the
    # feet 22 wide × 100 overall in the end view; a Ø20 boss 15 tall with a
    # 3 wall (Ø14 bore, through the plate) 30 from the right end; R2 at the
    # boss base (the other R2s — lug/side-face and lug/underside junctions —
    # can't be applied over the bridge, see agent_bugs_R1B; ~120 mm³).
    body = extrude(Sketch(top(0)).rect(0, -40, 125, 40), (60, 0), 20)
    relief = Sketch(front(-41)).rounded_poly([(-1, -1), (110, -1), (110, 6), (-1, 6)], [0, 0, 6, 0])
    extrude(relief, (50, 3), 82, cut=[body])
    slot = Sketch(top(-1)).rounded_poly([(-1, -15.5), (62, -15.5), (62, 15.5), (-1, 15.5)], [0, 6, 6, 0])
    extrude(slot, (30, 0), 22, cut=[body])
    extrude(Sketch(top(20)).circle((95, 0), 10).circle((95, 0), 7), (95, 8.5), 15, union=[body])
    extrude(Sketch(top(-1)).circle((95, 0), 7), (95, 0), 22, cut=[body])
    for z0 in (15.5, -50):
        extrude(Sketch(front(z0)).circle((11, 6), 11), (11, -3), 34.5, union=[body])
    extrude(Sketch(front(-51)).circle((11, 6), 6), (11, 6), 102, cut=[body])
    rim = edges_where(body, lambda e: abs(e["midpoint"][1] - 20) < 0.3
                      and abs(math.hypot(e["midpoint"][0] - 95, e["midpoint"][2]) - 10) < 0.3)
    fillet(body, 2.0, rim)
    return body


@problem("4.9", 141606, features=("Extrude Boss", "Extrude Cut"))
def p4_9():
    # Jaw block, 120 to the theoretical point of the 52° nose. Head 28 × 61
    # × 52 with a 23 × 11 slot along its top and a 10-deep × 38-wide slot
    # through its full height at the left end; shank 41 × 29 from x = 28,
    # tapering at 52° included from x = 78 to a flat tip at x = 111 (33) —
    # the apex at 120 fixes the start at 78; the top steps down 12 at
    # x = 98 (22 from the apex); Ø11 across at (78, 17), on the taper start.
    body = extrude(Sketch(top(0)).rect(0, -30.5, 28, 30.5), (14, 0), 52)
    extrude(Sketch(bottom(52)).rect(-1, -11.5, 29, 11.5), (14, 0), 11, cut=[body])
    extrude(Sketch(top(-1)).rect(-1, -19, 10, 19), (5, 0), 54, cut=[body])
    wt = 20.5 - 33 * math.tan(math.radians(26))
    extrude(Sketch(top(0)).poly([(28, -20.5), (78, -20.5), (111, -wt), (111, wt), (78, 20.5), (28, 20.5)]),
            (50, 0), 29, union=[body])
    extrude(Sketch(front(-25)).rect(98, 17, 113, 30), (105, 25), 50, cut=[body])
    extrude(Sketch(front(-25)).circle((78, 17), 5.5), (78, 17), 50, cut=[body])
    return body


@problem("4.50", 238068, features=("Extrude Boss", "Extrude Cut"))
def p4_50():
    # Asymmetric angle bracket. Upright block 36 thick (z -36..0): profile
    # (x, y) with the vertical face at x = 125, top flat 12 wide at y = 90
    # and the 42° hypotenuse running all the way down to y = 0 (the back
    # view shows it reaching the bottom at 13 from the origin end). Base bar
    # 32 × 16 × 125 in front of it (z 0..32) with its outer top edge
    # chamfered at 50° from vertical down to a 4-tall end face. Notch: the
    # back 11 mm of the upright removed above the plane perpendicular to
    # the hypotenuse 15 down the slope from the top corner (reads as 11 ×
    # 10 in the end view since 15·sin 42° = 10). 2 × Ø13 through, 20 off
    # the hypotenuse at heights 56 and 31 (40 and 15 above the base top);
    # Ø12 × 11 deep normal to the hypotenuse, 67 up the slope, 17 from the
    # back face.
    a = math.radians(42); ta = math.tan(a)
    x0 = 113 - 90 / ta                                       # hypotenuse foot at y = 0 (13.04)
    body = extrude(Sketch(front(-36)).poly([(x0, 0), (125, 0), (125, 90), (113, 90)]), (100, 40), 36)
    run = 12 / math.tan(math.radians(40))
    base = Sketch(right(0)).poly([(0, 0), (-32, 0), (-32, 4), (-(32 - run), 16), (0, 16)])
    extrude(base, (-10, 8), 125, union=[body])
    d = (math.cos(a), math.sin(a)); nrm = (-math.sin(a), math.cos(a))
    P1 = (113 - 15 * d[0], 90 - 15 * d[1])
    far = (135, P1[1] - (135 - P1[0]) * (math.cos(a) / math.sin(a)))   # cut plane meets x = 135
    notch = Sketch(front(-37)).poly([P1, far, (135, 95), (P1[0] + 20 * nrm[0], P1[1] + 20 * nrm[1])])
    extrude(notch, (120, 88), 12, cut=[body])
    def hole_x(y):  # 20 from the hypotenuse (line through (113, 90) at 42°)
        return (y + (ta * 113 - 90) + 20 * math.sqrt(1 + ta * ta)) / ta
    extrude(Sketch(front(-37)).circle((hole_x(56), 56), 6.5).circle((hole_x(31), 31), 6.5), (hole_x(56), 56), 38, cut=[body])
    extrude(Sketch(front(-37)).circle((hole_x(31), 31), 6.5), (hole_x(31), 31), 38, cut=[body])
    c = (x0 + 67 * d[0], 67 * d[1], -19.0)
    o = (c[0] + nrm[0], c[1] + nrm[1], c[2])
    hs = Sketch(plane_at(o, (0, 0, 1), (d[0], d[1], 0))).circle((0, 0), 6)
    extrude(hs, (0, 0), -12, cut=[body])
    return body


@problem("4.58", 81002, features=("Extrude Boss", "Extrude Cut", "Sketch: Slot"))
def p4_58():
    # Square tube 50 × 50 × 90 long (x), 5 walls, open both ends. Mid-length:
    # an obround boss on top (R10 ends 20 apart, 3 wall, 7 tall) with its
    # R7 slot through the top wall; Ø25 bosses with Ø19 bores on the front
    # and back (74 overall → 12 long each), bores through both walls; Ø8
    # through both walls 35 either side of mid-length. At the x = 0 end an
    # 8 × 10 notch in the top wall 7 in from one side (10 from the boss
    # centreline); at the x = 90 end Detail B's R4 U-slot, 8 wide, 10 deep,
    # centred 15 from the other side.
    body = extrude(Sketch(right(0)).rect(-25, 0, 25, 50).rect(-20, 5, 20, 45), (22.5, 25), 90)
    extrude(Sketch(top(50)).slot((35, 0), (55, 0), 10).slot((35, 0), (55, 0), 7), (45, 8.5), 7, union=[body])
    extrude(Sketch(top(44)).slot((35, 0), (55, 0), 7), (45, 0), 14, cut=[body])
    extrude(Sketch(front(25)).circle((45, 25), 12.5).circle((45, 25), 9.5), (45, 36), 12, union=[body])
    extrude(Sketch(back(-25)).circle((-45, 25), 12.5).circle((-45, 25), 9.5), (-45, 36), 12, union=[body])
    extrude(Sketch(front(-38)).circle((45, 25), 9.5), (45, 25), 76, cut=[body])
    for x in (10, 80):
        extrude(Sketch(front(-38)).circle((x, 25), 4), (x, 25), 76, cut=[body])
    extrude(Sketch(top(44)).rect(-1, 10, 10, 18), (5, 14), 8, cut=[body])
    extrude(Sketch(top(44)).slot((84, -10), (95, -10), 4), (88, -10), 8, cut=[body])
    return body


@problem("4.60", 134393, features=("Extrude Boss", "Extrude Cut", "Sketch: Slot", "Sketch: Arcs"))
def p4_60():
    # Channel-backed plate. Plate 75 wide × 10 thick (z -10..0): top edge 54
    # above the origin (the slot centre), R13 top corners, Ø10 × 2 on 35
    # centres 13 below the top, straight sides down to 21 below the origin
    # (the channel's bottom), then tangents to the R25 end about the Ø23
    # hole 127 below the top. The plate is cut through its full width by
    # the 13-tall gap centred on the origin (the side view and Detail A both
    # show the strip open there). C-channel on the front, 75 long: web 10
    # thick, 42 tall, its outer face 37 from the plate's back (Detail A),
    # flanges 10 thick spanning the 17 between plate and web; R6 slot on 35
    # centres through the web.
    C = (0.0, -73.0); R = 25.0; P = (37.5, -21.0)
    d = math.hypot(P[0] - C[0], P[1] - C[1]); alpha = math.acos(R / d)
    aT = math.atan2(P[1] - C[1], P[0] - C[0]) - alpha
    T = (C[0] + R * math.cos(aT), C[1] + R * math.sin(aT))
    top = (Sketch(front(-10)).rounded_poly([(-37.5, -21), (-37.5, 54), (37.5, 54), (37.5, -21)], [0, 13, 13, 0])
           .circle((-17.5, 41), 5).circle((17.5, 41), 5))
    body = extrude(top, (0, 20), 10)
    lug = (Sketch(front(-10)).line((-37.5, -21), (37.5, -21)).line((37.5, -21), T)
           .arc(C, R, 180 - math.degrees(aT), 360 + math.degrees(aT))      # round the bottom, T' to T
           .line((-T[0], T[1]), (-37.5, -21)).circle(C, 11.5))
    extrude(lug, (0, -40), 10, union=[body])
    extrude(Sketch(front(-11)).rect(-40, -6.5, 40, 6.5), (0, 0), 12, cut=[body])
    ch = Sketch(right(-37.5)).poly([(0, 21), (-27, 21), (-27, -21), (0, -21), (0, -11), (-17, -11), (-17, 11), (0, 11)])
    extrude(ch, (-22, 0), 75, union=[body])
    extrude(Sketch(front(28)).slot((-17.5, 0), (17.5, 0), 6), (0, 0), -12, cut=[body])
    return body


@problem("4.66", 104107, features=("Extrude Boss", "Extrude Cut", "Sketch: Slot", "Fillet and Chamfer"))
def p4_66():
    # Gable block, origin at the back face's bottom centre; z runs toward
    # the front (35 deep overall). Front profile: 84 wide, sides vertical
    # to y = 35, then 33° from vertical up to the y = 53 bend (the side
    # view's 18), then 51° from vertical up to the 71 flat (16.2 wide).
    # The main body is 27 deep (z 8..35); a 25-wide lug with the same roof
    # fills the back 8 (top view). Full-width front notch y 10..47 × 12
    # deep (side view / the tiny 8 × 12 slab patches in the top view);
    # 35° chamfer with a 15 run on the front top edge; Ø8 slot 8 wide
    # between centres (0, 18) and (0, 39) through the back 23.
    t33 = math.tan(math.radians(33)); t51 = math.tan(math.radians(51)); t35 = math.tan(math.radians(35))
    x53 = 42 - 18 * t33; x71 = x53 - 18 * t51
    prof = [(-42, 0), (42, 0), (42, 35), (x53, 53), (x71, 71), (-x71, 71), (-x53, 53), (-42, 35)]
    body = extrude(Sketch(front(0)).poly(prof), (0, 10), 35)
    for sx in (1, -1):
        extrude(Sketch(front(-1)).rect(sx * 12.5, -1, sx * 50, 80), (sx * 30, 20), 9, cut=[body])
    extrude(Sketch(front(23)).rect(-50, 10, 50, 47), (0, 30), 13, cut=[body])
    y0 = 71 - 15 * t35
    zt = 35 - (75 - y0) / t35
    ch = Sketch(right(-50)).poly([(-35, y0), (-35, 75), (-zt, 75)])
    extrude(ch, (-34, 72), 100, cut=[body])
    extrude(Sketch(front(-1)).slot((0, 18), (0, 39), 4), (0, 28), 40, cut=[body])
    return body


@problem("4.39", 166787, features=("Extrude Boss", "Extrude Cut", "Sketch: Arcs"))
def p4_39():
    # Two identical D-shaped eyes, 22 thick, meeting face to face at x = 50:
    # each is a 64-wide rectangle from the hole centre out 50 plus an R32
    # semicircle, Ø36 through. The first lies flat (origin at its hole
    # centre, thickness along y); the second stands upright (thickness
    # along z) with its centre at x = 100. Nothing else joins them: the
    # tangent-edge lines at x = 0 and x = 100 are the flat/cylinder seams.
    flat = (Sketch(top(-11)).arc((0, 0), 32, 90, 270).line((0, -32), (50, -32))
            .line((50, -32), (50, 32)).line((50, 32), (0, 32)).circle((0, 0), 18))
    body = extrude(flat, (25, 0), 22)
    up = (Sketch(front(-11)).arc((100, 0), 32, -90, 90).line((100, 32), (50, 32))
          .line((50, 32), (50, -32)).line((50, -32), (100, -32)).circle((100, 0), 18))
    extrude(up, (75, 0), 22, union=[body])
    return body


@problem("4.55", 230344, features=("Extrude Boss", "Extrude Cut", "Sketch: Arcs", "Sketch: Trim"))
def p4_55():
    # Bell-crank lever. Hub Ø62 × 50 tall on the origin (z 0..50) with a
    # Ø26 bore and a 4-wide keyway to r = 18. Right arm: hull of the hub
    # and an R22 end 65 out, 10 thick at the hub's top (z 40..50), the end
    # a Ø44 boss 20 tall (z 40..60). Left arm: hull to an R22 end 120 out
    # at 30° below the −x axis, 10 thick at the hub's bottom (z 0..10),
    # its end a Ø44 boss 20 tall (z −10..10). Ø15 through both ends.
    E = (-120 * math.cos(math.radians(30)), -120 * math.sin(math.radians(30)))
    body = extrude(Sketch(front(40)).hull2((0, 0), 31, (65, 0), 22), (40, 0), 10)
    extrude(Sketch(front(40)).circle((65, 0), 22), (65, 0), 20, union=[body])
    extrude(Sketch(front(0)).hull2((0, 0), 31, E, 22), (E[0] / 2, E[1] / 2), 10, union=[body])
    extrude(Sketch(front(-10)).circle(E, 22), E, 20, union=[body])
    extrude(Sketch(front(0)).circle((0, 0), 31), (0, 0), 50, union=[body])
    extrude(Sketch(front(-1)).circle((0, 0), 13), (0, 0), 52, cut=[body])
    extrude(Sketch(front(-1)).rect(10, -2, 18, 2), (15, 0), 52, cut=[body])
    extrude(Sketch(front(-11)).circle((65, 0), 7.5), (65, 0), 72, cut=[body])
    extrude(Sketch(front(-11)).circle(E, 7.5), E, 72, cut=[body])
    return body
