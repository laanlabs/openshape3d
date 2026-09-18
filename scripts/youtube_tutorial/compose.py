#!/usr/bin/env python3
"""Compose the YouTube tutorial: raw simulator take + timeline + narration + music.

    compose.py <raw.mp4> <timeline.json> <out.mp4>

Layout 1920x1080: the iPad (landscape, 4:3) fills 1440x1080 on the left, a
480 px panel on the right shows the chapter title, subtitle and bullet
lines for the current segment. A title card opens, an outro card closes.
"""
import json, os, subprocess, sys, textwrap
from PIL import Image, ImageDraw, ImageFont

S = os.path.dirname(os.path.abspath(__file__))
RAW, TIMELINE, OUT = sys.argv[1:4]
SCRIPT_PATH = os.environ.get("TUT_SCRIPT", f"{S}/script.json")
TTS = os.environ.get("TUT_TTS", f"{S}/tts")
BUILD = os.environ.get("TUT_BUILD", f"{S}/build")
SCRIPT = json.load(open(SCRIPT_PATH))
TL = json.load(open(TIMELINE))
DUR = json.load(open(f"{TTS}/durations.json"))
ICON = os.environ.get("OS3D_ICON", "/Users/thelodgestudio/projects/openshape3d/openshape3d/Assets.xcassets/AppIcon.appiconset/icon-ios-1024x1024.png")
FF = os.environ.get("FFMPEG", "ffmpeg")
ENV = dict(os.environ, DYLD_FALLBACK_LIBRARY_PATH="/opt/homebrew/Cellar/x265/4.1/lib")

W, H = 1920, 1080
VW = 1440                       # video width; panel is W-VW
TITLE_S, OUTRO_S = 5.0, 8.0
BG = (16, 19, 24)
PANEL = (22, 26, 33)
FG = (240, 242, 246)
MUTED = (150, 158, 172)
ACCENT = (56, 142, 245)

def font(size, bold=False):
    return ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", size, index=1 if bold else 0)

def icon(size):
    im = Image.open(ICON).convert("RGBA").resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=int(size * 0.22), fill=255)
    im.putalpha(mask)
    return im

def wrap(draw, text, f, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if draw.textlength(t, font=f) <= width:
            cur = t
        else:
            lines.append(cur); cur = w
    if cur:
        lines.append(cur)
    return lines

def panel_png(i, seg, path):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    x0 = VW
    d.rectangle([x0, 0, W, H], fill=PANEL + (255,))
    d.rectangle([x0, 0, x0 + 2, H], fill=(40, 46, 56, 255))
    pad = 36
    ic = icon(44)
    im.alpha_composite(ic, (x0 + pad, 40))
    d.text((x0 + pad + 58, 46), "OpenShape 3D", font=font(26, True), fill=FG)
    d.text((x0 + pad + 58, 76), os.environ.get("TUT_HEADER", "CAD basics & first part"), font=font(18), fill=MUTED)
    y = 170
    d.rectangle([x0 + pad, y, x0 + pad + 46, y + 5], fill=ACCENT + (255,))
    y += 26
    for line in wrap(d, seg["title"], font(42, True), W - x0 - 2 * pad):
        d.text((x0 + pad, y), line, font=font(42, True), fill=FG); y += 50
    y += 6
    for line in wrap(d, seg["sub"], font(26), W - x0 - 2 * pad):
        d.text((x0 + pad, y), line, font=font(26), fill=MUTED); y += 33
    y += 34
    for item in seg["lines"]:
        d.ellipse([x0 + pad, y + 11, x0 + pad + 9, y + 20], fill=ACCENT + (255,))
        lines = wrap(d, item, font(25), W - x0 - 2 * pad - 26)
        for line in lines:
            d.text((x0 + pad + 26, y), line, font=font(25), fill=FG); y += 32
        y += 12
    # progress
    n = len(SCRIPT)
    d.text((x0 + pad, H - 90), f"{i + 1} / {n}", font=font(20), fill=MUTED)
    bw = W - x0 - 2 * pad
    d.rectangle([x0 + pad, H - 56, x0 + pad + bw, H - 52], fill=(45, 51, 62, 255))
    d.rectangle([x0 + pad, H - 56, x0 + pad + int(bw * (i + 1) / n), H - 52], fill=ACCENT + (255,))
    im.save(path)

def card(title, sub, foot, path, big=True):
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    # soft radial glow
    glow = Image.new("RGB", (W, H), BG)
    gd = ImageDraw.Draw(glow)
    for r in range(600, 0, -20):
        a = int(18 * (1 - r / 600))
        gd.ellipse([W // 2 - r, H // 2 - r + 40, W // 2 + r, H // 2 + r + 40], fill=(16 + a, 19 + a * 2, 24 + a * 4))
    im = glow
    d = ImageDraw.Draw(im)
    ic = icon(200 if big else 140)
    y = 200 if big else 240
    im.paste(ic, ((W - ic.width) // 2, y), ic)
    y += ic.height + 40
    f = font(96 if big else 72, True)
    d.text(((W - d.textlength(title, font=f)) // 2, y), title, font=f, fill=FG); y += (110 if big else 90)
    f = font(44)
    d.text(((W - d.textlength(sub, font=f)) // 2, y), sub, font=f, fill=MUTED); y += 70
    f = font(28)
    for line in foot:
        d.text(((W - d.textlength(line, font=f)) // 2, y), line, font=f, fill=ACCENT); y += 40
    im.save(path)

def run(args):
    print(" ".join(a if " " not in a else repr(a) for a in args[:12]), "…", flush=True)
    subprocess.run(args, check=True, env=ENV)

os.makedirs(BUILD, exist_ok=True)
starts = {s["id"]: s for s in TL["segments"]}
total = TL["total"]

# 1. panels
overlays = []
for i, seg in enumerate(SCRIPT):
    p = f"{BUILD}/panel-{i:02d}.png"
    panel_png(i, seg, p)
    t = starts[seg["id"]]
    overlays.append((p, t["start"], t["end"]))
card("OpenShape 3D", os.environ.get("TUT_TITLE", "CAD basics and your first part"), [os.environ.get("TUT_SUBTITLE", "Free, open-source solid modeling for iPad")], f"{BUILD}/title.png")
card("Thanks for watching", "github.com/laanlabs/openshape3d", ["Free · open source · no account", "Like and subscribe for more tutorials"], f"{BUILD}/outro.png", big=False)

REUSE = os.environ.get("REUSE_VIDEO") and os.path.exists(f"{BUILD}/video.mp4")
# 2. main video: rotate the framebuffer upright, fit, pad, overlays, fades
fc = [f"[0:v]transpose={os.environ.get('TUT_TRANSPOSE', '1')},tpad=stop_mode=clone:stop_duration=20,fps=30,scale={VW}:{H}:force_original_aspect_ratio=decrease:flags=lanczos,"
      f"pad={W}:{H}:0:(oh-ih)/2:color=0x{BG[0]:02x}{BG[1]:02x}{BG[2]:02x},format=rgba[base]"]
prev = "base"
for k, (p, a, b) in enumerate(overlays):
    fc.append(f"[{prev}][{k + 1}:v]overlay=0:0:enable='between(t,{a:.2f},{b:.2f})'[o{k}]")
    prev = f"o{k}"
fc.append(f"[{prev}]format=yuv420p,fade=t=in:st=0:d=0.6,fade=t=out:st={total - 0.8:.2f}:d=0.8[v]")
args = [FF, "-y", "-loglevel", "error", "-i", RAW]
for p, _, _ in overlays:
    args += ["-loop", "1", "-i", p]
args += ["-filter_complex", ";".join(fc), "-map", "[v]", "-t", f"{total:.2f}",
         "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-r", "30", "-an", f"{BUILD}/main.mp4"]
if not REUSE: run(args)

# 3. cards
for name, dur in (("title", TITLE_S), ("outro", OUTRO_S)):
    if not REUSE: run([FF, "-y", "-loglevel", "error", "-loop", "1", "-i", f"{BUILD}/{name}.png", "-t", str(dur),
         "-vf", f"fps=30,format=yuv420p,fade=t=in:st=0:d=0.8,fade=t=out:st={dur - 0.8}:d=0.8",
         "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-r", "30", "-an", f"{BUILD}/{name}.mp4"])

# 4. concat video
with open(f"{BUILD}/concat.txt", "w") as f:
    for name in ("title", "main", "outro"):
        f.write(f"file '{BUILD}/{name}.mp4'\n")
if not REUSE: run([FF, "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", f"{BUILD}/concat.txt", "-c", "copy", f"{BUILD}/video.mp4"])
full = TITLE_S + total + OUTRO_S

# 5. audio: narration at offsets (+title), music bed ducked under speech
ins = [FF, "-y", "-loglevel", "error", "-i", f"{BUILD}/video.mp4", "-i", f"{S}/music-bed.wav"]
af, mixes = [], []
for k, seg in enumerate(SCRIPT):
    ins += ["-i", f"{TTS}/{seg['id']}." + os.environ.get("TUT_TTS_EXT", "aiff")]
    off = int((TITLE_S + starts[seg["id"]]["start"] + 0.35) * 1000)
    af.append(f"[{k + 2}:a]aformat=sample_rates=48000:channel_layouts=stereo,adelay={off}|{off}[n{k}]")
    mixes.append(f"[n{k}]")
af.append(f"{''.join(mixes)}amix=inputs={len(mixes)}:normalize=0:dropout_transition=0,loudnorm=I=-16:TP=-1.5:LRA=11[voice]")
quiet_to = TITLE_S + total
af.append(f"[1:a]atrim=0:{full:.2f},volume='if(lt(t,{TITLE_S}),0.9,if(gt(t,{quiet_to:.2f}),0.9,0.30))':eval=frame,"
          f"afade=t=in:st=0:d=1.5,afade=t=out:st={full - 3:.2f}:d=3[music]")
af.append("[voice][music]amix=inputs=2:normalize=0:duration=longest,alimiter=limit=0.95[a]")
ins += ["-filter_complex", ";".join(af), "-map", "0:v", "-map", "[a]", "-t", f"{full:.2f}",
        "-c:v", "copy", "-c:a", "aac", "-b:a", "256k", "-ar", "48000", "-movflags", "+faststart", OUT]
run(ins)
print("wrote", OUT, "length", round(full, 1), "s")
