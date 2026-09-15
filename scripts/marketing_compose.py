#!/usr/bin/env python3
"""Compose App Store screenshots from raw simulator captures.

    python3 scripts/marketing_compose.py [RAW_DIR] [OUT_DIR]

RAW_DIR (default marketing/raw) holds native-resolution `simctl io screenshot`
captures named `<device>-<slug>.png`, device `ipad` (iPad Pro 13-inch, 2064 ×
2752) or `iphone` (iPhone 17 Pro Max, 1320 × 2868). Each becomes a framed,
captioned PNG at the same App Store size in OUT_DIR/<device>/, numbered in
SHOTS order, plus OUT_DIR/overview.png for review. The look follows the app
icon: navy blueprint ground, the icon's blue, a silver-edged device.

Output is RGB (App Store Connect refuses screenshots with an alpha channel).
"""

import os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZES = {"ipad": (2064, 2752), "iphone": (1320, 2868)}

# (slug, kicker, headline, subhead). A "\n" in a headline is a chosen break;
# a {device} placeholder becomes "iPad" / "iPhone".
SHOTS = [
    ("hero", "OPENSHAPE 3D", "Real CAD,\nright on your {device}",
     "Precise solid modeling on a true B-rep kernel."),
    ("sketch", "SKETCH", "Sketch with\nexact dimensions",
     "Lines, arcs, splines and constraints that hold."),
    ("extrude", "MODEL", "Push, pull\nand extrude",
     "Drag a face or type a value. The preview follows."),
    ("history", "PARAMETRIC", "Every step\nstays editable",
     "Change a radius and the whole model rebuilds."),
    ("revolve", "SHAPE", "Revolve, shell,\nfillet and more",
     "The tools you expect from desktop CAD."),
    ("export", "OPEN SOURCE", "Free and open.\nYour files stay yours.",
     "Export STEP, STL, 3MF, OBJ and DXF."),
]

# Shots whose lower viewport is empty grid: framed larger, cropped at the
# bottom. The rest keep the whole device (their bottom bar is the point).
BLEED = {"hero", "sketch", "history", "revolve"}

FONT = "/System/Library/Fonts/SFNS.ttf"
NAVY_TOP, NAVY_BOTTOM = (8, 16, 34), (20, 40, 78)
BLUE = (47, 123, 245)
SUB = (168, 186, 216)

# Per device: text sizes, top margin, device-frame proportions.
LAYOUT = {
    "ipad":   dict(kicker=44, head=124, sub=56, top=170, gap=90, bottom=120,
                   max_w=0.80, bleed_w=0.90, bezel=0.022, radius=0.035),
    "iphone": dict(kicker=38, head=104, sub=46, top=190, gap=80, bottom=110,
                   max_w=0.84, bleed_w=0.88, bezel=0.034, radius=0.135),
}


def font(size, weight):
    f = ImageFont.truetype(FONT, size)
    f.set_variation_by_name(weight)
    return f


def background(w, h):
    bg = Image.new("RGB", (w, h))
    px = ImageDraw.Draw(bg)
    for y in range(h):
        t = y / (h - 1)
        px.line([(0, y), (w, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(NAVY_TOP, NAVY_BOTTOM)))
    # Blueprint grid: minor every 48 px, major every 4th.
    grid = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    g = ImageDraw.Draw(grid)
    step = 48
    for i, x in enumerate(range(0, w, step)):
        g.line([(x, 0), (x, h)], fill=(120, 160, 230, 26 if i % 4 else 44), width=2 if i % 4 == 0 else 1)
    for i, y in enumerate(range(0, h, step)):
        g.line([(0, y), (w, y)], fill=(120, 160, 230, 26 if i % 4 else 44), width=2 if i % 4 == 0 else 1)
    bg = Image.alpha_composite(bg.convert("RGBA"), grid)
    return bg


def glow(canvas, box):
    x0, y0, x1, y1 = box
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    pad_x, pad_y = (x1 - x0) * 0.25, (y1 - y0) * 0.12
    d.ellipse([x0 - pad_x, y0 + pad_y, x1 + pad_x, y1 - pad_y], fill=BLUE + (110,))
    layer = layer.filter(ImageFilter.GaussianBlur((x1 - x0) * 0.18))
    return Image.alpha_composite(canvas, layer)


def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return m


def device(canvas, shot, box, L):
    x0, y0, x1, y1 = box
    fw, fh = x1 - x0, y1 - y0
    bez = round(fw * L["bezel"])
    r_out = round(fw * L["radius"])
    r_in = max(r_out - bez, 8)
    # Shadow.
    sh = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([x0, y0 + fw * 0.03, x1, y1 + fw * 0.03], radius=r_out, fill=(0, 0, 0, 170))
    canvas = Image.alpha_composite(canvas, sh.filter(ImageFilter.GaussianBlur(fw * 0.035)))
    d = ImageDraw.Draw(canvas)
    # Silver rim, then the black bezel inside it.
    d.rounded_rectangle([x0, y0, x1, y1], radius=r_out, fill=(150, 158, 172))
    rim = max(3, round(fw * 0.003))
    d.rounded_rectangle([x0 + rim, y0 + rim, x1 - rim, y1 - rim], radius=r_out - rim, fill=(10, 11, 14))
    sw, sh_ = fw - 2 * bez, fh - 2 * bez
    screen = shot.convert("RGB").resize((sw, sh_), Image.LANCZOS)
    canvas.paste(screen, (x0 + bez, y0 + bez), rounded_mask((sw, sh_), r_in))
    return canvas


def text_block(canvas, w, L, kicker, head, sub):
    d = ImageDraw.Draw(canvas)
    y = L["top"]
    fk, fh, fs = font(L["kicker"], "Semibold"), font(L["head"], "Bold"), font(L["sub"], "Regular")
    # Kicker: tracked-out caps in the icon blue.
    spacing = L["kicker"] * 0.18
    widths = [d.textlength(c, font=fk) for c in kicker]
    total = sum(widths) + spacing * (len(kicker) - 1)
    x = (w - total) / 2
    for c, cw in zip(kicker, widths):
        d.text((x, y), c, font=fk, fill=(110, 165, 255))
        x += cw + spacing
    y += L["kicker"] * 1.9
    for line in head.split("\n"):
        d.text((w / 2, y), line, font=fh, fill=(255, 255, 255), anchor="ma")
        y += L["head"] * 1.08
    y += L["sub"] * 0.55
    d.text((w / 2, y), sub, font=fs, fill=SUB, anchor="ma")
    return y + L["sub"] * 1.2


def compose(dev, shot_path, spec):
    slug, kicker, head, sub = spec
    w, h = SIZES[dev]
    L = LAYOUT[dev]
    shot = Image.open(shot_path)
    if shot.size != (w, h):
        sys.exit(f"{shot_path}: {shot.size}, expected native {w}x{h}")
    canvas = background(w, h)
    name = "iPad" if dev == "ipad" else "iPhone"
    text_bottom = text_block(canvas, w, L, kicker, head.format(device=name), sub.format(device=name))
    if slug in BLEED:
        # Larger device running off the bottom edge: the empty lower viewport
        # is what gets cropped, and the UI above it reads bigger.
        fw = w * L["bleed_w"]
        fh = fw * h / w
        x0 = round((w - fw) / 2)
        y0 = round(text_bottom + L["gap"])
    else:
        # The largest whole device between the text and the bottom margin.
        avail_h = h - (text_bottom + L["gap"]) - L["bottom"]
        fw = min(w * L["max_w"], avail_h * w / h)
        fh = fw * h / w
        x0 = round((w - fw) / 2)
        y0 = round(text_bottom + L["gap"] + (avail_h - fh) / 2)
    box = (x0, y0, x0 + round(fw), y0 + round(fh))
    canvas = glow(canvas, box)
    canvas = device(canvas, shot, box, L)
    return canvas.convert("RGB")


def main():
    raw = sys.argv[1] if len(sys.argv) > 1 else "marketing/raw"
    out = sys.argv[2] if len(sys.argv) > 2 else "marketing/app-store"
    made = {}
    for dev in SIZES:
        os.makedirs(os.path.join(out, dev), exist_ok=True)
        # Numbering follows SHOTS, so a shot added or dropped renumbers the
        # rest: clear the old set rather than leave stale duplicates to upload.
        for old in os.listdir(os.path.join(out, dev)):
            if old.endswith(".png"):
                os.remove(os.path.join(out, dev, old))
        n = 0
        for spec in SHOTS:
            src = os.path.join(raw, f"{dev}-{spec[0]}.png")
            if not os.path.exists(src):
                continue
            n += 1
            img = compose(dev, src, spec)
            dst = os.path.join(out, dev, f"{n:02d}-{spec[0]}.png")
            img.save(dst, optimize=True)
            made.setdefault(dev, []).append(img)
            print(f"{dst}  {img.size[0]}x{img.size[1]}")
    # Review sheet: every device's row, scaled to one height.
    rows = [imgs for imgs in made.values() if imgs]
    if rows:
        th, pad = 900, 30
        scaled = [[im.resize((round(im.width * th / im.height), th), Image.LANCZOS) for im in r] for r in rows]
        sheet_w = max(sum(im.width for im in r) + pad * (len(r) + 1) for r in scaled)
        sheet = Image.new("RGB", (sheet_w, (th + pad) * len(scaled) + pad), (30, 32, 38))
        for i, r in enumerate(scaled):
            x = pad
            for im in r:
                sheet.paste(im, (x, pad + i * (th + pad)))
                x += im.width + pad
        sheet.save(os.path.join(out, "overview.png"))
        print(os.path.join(out, "overview.png"))


if __name__ == "__main__":
    main()
